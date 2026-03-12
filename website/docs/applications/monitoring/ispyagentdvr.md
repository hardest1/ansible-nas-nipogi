---
title: "iSpy Agent DVR"
---

Homepage: [https://www.ispyconnect.com/agent.aspx](https://www.ispyconnect.com/agent.aspx)

iSpy Agent DVR is a self-hosted video surveillance and camera monitoring platform.

## Usage

Set `ispyagentdvr_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

The Agent DVR web interface can be found at [http://ansible_nas_host_or_ip:8097](http://ansible_nas_host_or_ip:8097).

This role also exposes TURN traffic on UDP port `3478` and Agent DVR media ports on UDP range `50000-50010`.