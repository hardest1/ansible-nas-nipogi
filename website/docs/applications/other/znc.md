---
title: "ZNC"
---

Homepage: [https://wiki.znc.in/ZNC](https://wiki.znc.in/ZNC)

ZNC is an IRC bouncer that stays connected to your IRC networks and buffers messages while you are away.

## Usage

Set `znc_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

This role exposes the ZNC service on [ansible_nas_host_or_ip:6677](irc://ansible_nas_host_or_ip:6677). It is not a standard web interface role.

Before enabling it, you will usually want to override the default user and password variables in the role defaults.