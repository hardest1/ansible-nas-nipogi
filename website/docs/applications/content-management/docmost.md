---
title: "Docmost"
---

Homepage: [https://docmost.com/docs/self-hosting](https://docmost.com/docs/self-hosting)

## Usage

Set `docmost_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

The Docmost web interface can be found at [http://ansible_nas_host_or_ip:3003](http://ansible_nas_host_or_ip:3003).

Override `docmost_public_url` if you want Docmost to generate links and cookies for a different hostname, such as your externally published Traefik URL.