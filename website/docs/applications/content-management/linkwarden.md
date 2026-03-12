---
title: "Linkwarden"
---

Homepage: [https://linkwarden.app/](https://linkwarden.app/)

Linkwarden is a self-hosted bookmark manager for collecting, organizing, and archiving links.

## Usage

Set `linkwarden_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

The Linkwarden web interface can be found at [http://ansible_nas_host_or_ip:22412](http://ansible_nas_host_or_ip:22412).

You should override `linkwarden_nextauth_secret` and `linkwarden_pgsql_password` before enabling the role.