#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
subject="${repo_root}/bin/ansible-nas"
test_root="$(mktemp -d)"

cleanup() {
    rm -rf -- "${test_root}"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local expected="$2"

    grep -F -- "${expected}" "${file}" >/dev/null ||
        fail "${file} does not contain: ${expected}"
}

assert_not_exists() {
    local path="$1"

    [[ ! -e "${path}" ]] || fail "${path} still exists"
}

install_fakes() {
    local fake_bin="$1"

    mkdir -p "${fake_bin}"

    cat >"${fake_bin}/op" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"${TEST_STATE}/op.log"

if [[ "${OP_FAIL:-0}" == "1" ]]; then
    exit 23
fi

case "${1:-} ${2:-}" in
    "read op://hw-lan/ansible-nas-nipogi-inventory/notesPlain")
        printf '%s\n' \
            '```ini' \
            '[nas]' \
            'nipogi ansible_host=192.0.2.10' \
            '```'
        ;;
    "read op://hw-lan/ansible-nas-nipogi-config/notesPlain")
        printf '%s\n' \
            '```yaml' \
            '---' \
            'ansible_nas_hostname: nipogi' \
            'example_secret: test-only' \
            '```'
        ;;
    *)
        printf 'unexpected op arguments: %s\n' "$*" >&2
        exit 24
        ;;
esac
EOF

    cat >"${fake_bin}/ansible-inventory" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == "-i" ]] || exit 31
inventory_file="${2:-}"
config_file="$(dirname "${inventory_file}")/group_vars/nas.yml"

[[ -f "${inventory_file}" ]] || exit 32
[[ -f "${config_file}" ]] || exit 33
[[ "$(stat -c '%a' "${inventory_file}")" == "600" ]] || exit 34
[[ "$(stat -c '%a' "${config_file}")" == "600" ]] || exit 35
[[ "$(stat -c '%a' "$(dirname "${inventory_file}")")" == "700" ]] || exit 36
[[ "$(head -n 1 "${inventory_file}")" == "[nas]" ]] || exit 37
[[ "$(head -n 1 "${config_file}")" == "---" ]] || exit 38

grep -F 'nipogi ansible_host=192.0.2.10' "${inventory_file}" >/dev/null
grep -F 'ansible_nas_hostname: nipogi' "${config_file}" >/dev/null

printf '%s\n' "${inventory_file}" >"${TEST_STATE}/runtime-inventory-path"
printf '%s\n' "$*" >"${TEST_STATE}/inventory-args"
EOF

    cat >"${fake_bin}/ansible-playbook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[[ "${PWD}" == "${EXPECTED_REPO_ROOT}" ]] || exit 41
[[ "${1:-}" == "-i" ]] || exit 42
inventory_file="${2:-}"
config_file="$(dirname "${inventory_file}")/group_vars/nas.yml"

[[ -f "${inventory_file}" ]] || exit 43
[[ -f "${config_file}" ]] || exit 44

printf '%s\n' "$*" >"${TEST_STATE}/playbook-args"

exit "${PLAYBOOK_EXIT:-0}"
EOF

    chmod +x \
        "${fake_bin}/op" \
        "${fake_bin}/ansible-inventory" \
        "${fake_bin}/ansible-playbook"
}

run_success_case() {
    local case_root="${test_root}/success"
    local fake_bin="${case_root}/bin"
    local runtime_root="${case_root}/runtime"
    local state="${case_root}/state"

    mkdir -p "${runtime_root}" "${state}"
    chmod 700 "${runtime_root}"
    install_fakes "${fake_bin}"

    PATH="${fake_bin}:${PATH}" \
        XDG_RUNTIME_DIR="${runtime_root}" \
        TEST_STATE="${state}" \
        EXPECTED_REPO_ROOT="${repo_root}" \
        "${subject}" nipogi --check --limit nas

    assert_contains "${state}/op.log" \
        "read op://hw-lan/ansible-nas-nipogi-inventory/notesPlain"
    assert_contains "${state}/op.log" \
        "read op://hw-lan/ansible-nas-nipogi-config/notesPlain"
    assert_contains "${state}/inventory-args" "--graph"
    assert_contains "${state}/playbook-args" \
        "nas.yml -b -K --check --limit nas"

    runtime_inventory="$(<"${state}/runtime-inventory-path")"
    assert_not_exists "$(dirname "${runtime_inventory}")"
}

run_invalid_host_case() {
    local case_root="${test_root}/invalid-host"
    local fake_bin="${case_root}/bin"
    local runtime_root="${case_root}/runtime"
    local state="${case_root}/state"

    mkdir -p "${runtime_root}" "${state}"
    chmod 700 "${runtime_root}"
    install_fakes "${fake_bin}"

    if PATH="${fake_bin}:${PATH}" \
        XDG_RUNTIME_DIR="${runtime_root}" \
        TEST_STATE="${state}" \
        EXPECTED_REPO_ROOT="${repo_root}" \
        "${subject}" '../nipogi' 2>"${state}/error.log"; then
        fail "unsafe host name was accepted"
    fi

    assert_not_exists "${state}/op.log"
}

run_fetch_failure_case() {
    local case_root="${test_root}/fetch-failure"
    local fake_bin="${case_root}/bin"
    local runtime_root="${case_root}/runtime"
    local state="${case_root}/state"

    mkdir -p "${runtime_root}" "${state}"
    chmod 700 "${runtime_root}"
    install_fakes "${fake_bin}"

    if PATH="${fake_bin}:${PATH}" \
        XDG_RUNTIME_DIR="${runtime_root}" \
        TEST_STATE="${state}" \
        EXPECTED_REPO_ROOT="${repo_root}" \
        OP_FAIL=1 \
        "${subject}" nipogi; then
        fail "1Password fetch failure was ignored"
    fi

    assert_not_exists "${state}/playbook-args"
    [[ -z "$(find "${runtime_root}" -mindepth 1 -print -quit)" ]] ||
        fail "runtime files remained after a fetch failure"
}

run_playbook_failure_case() {
    local case_root="${test_root}/playbook-failure"
    local fake_bin="${case_root}/bin"
    local runtime_root="${case_root}/runtime"
    local state="${case_root}/state"

    mkdir -p "${runtime_root}" "${state}"
    chmod 700 "${runtime_root}"
    install_fakes "${fake_bin}"

    if PATH="${fake_bin}:${PATH}" \
        XDG_RUNTIME_DIR="${runtime_root}" \
        TEST_STATE="${state}" \
        EXPECTED_REPO_ROOT="${repo_root}" \
        PLAYBOOK_EXIT=19 \
        "${subject}" nipogi; then
        fail "Ansible failure was ignored"
    else
        status="$?"
    fi

    [[ "${status}" == "19" ]] ||
        fail "Ansible exit status was not preserved"
    [[ -z "$(find "${runtime_root}" -mindepth 1 -print -quit)" ]] ||
        fail "runtime files remained after an Ansible failure"
}

run_missing_runtime_case() {
    local case_root="${test_root}/missing-runtime"
    local fake_bin="${case_root}/bin"
    local state="${case_root}/state"

    mkdir -p "${state}"
    install_fakes "${fake_bin}"

    if env -u XDG_RUNTIME_DIR \
        PATH="${fake_bin}:${PATH}" \
        TEST_STATE="${state}" \
        EXPECTED_REPO_ROOT="${repo_root}" \
        "${subject}" nipogi 2>"${state}/error.log"; then
        fail "missing XDG_RUNTIME_DIR was accepted"
    fi

    assert_not_exists "${state}/op.log"
}

[[ -x "${subject}" ]] || fail "${subject} is not executable"

run_success_case
run_invalid_host_case
run_fetch_failure_case
run_playbook_failure_case
run_missing_runtime_case

printf 'All 1Password runner tests passed.\n'
