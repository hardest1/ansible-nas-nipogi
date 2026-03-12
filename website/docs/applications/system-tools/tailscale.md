---
title: "Tailscale"
---

Homepage: [https://tailscale.com/](https://tailscale.com/)

Tailscale is a mesh VPN built on WireGuard for private connectivity between your devices and services.

## Usage

Set `tailscale_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

This role does not expose a local web interface by default. Management happens through the Tailscale admin console at [https://login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines).

Before enabling the role, set the authentication variables it expects in your inventory, such as `tailscale_oauth_secret`, `tailscale_deviceid`, and `tailscale_token` if you want the homepage widget to work.