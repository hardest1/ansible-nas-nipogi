---
title: "Plant-it"
---

Homepage: [https://github.com/MDeLuise/plant-it](https://github.com/MDeLuise/plant-it)

Plant-it is a self-hosted plant care and monitoring application.

## Usage

Set `plant_it_enabled: true` in your `inventories/<your_inventory>/group_vars/nas.yml` file.

The Plant-it web interface can be found at [http://ansible_nas_host_or_ip:9200](http://ansible_nas_host_or_ip:9200).

The backend API is exposed on port `9201` for integrations and the homepage widget.