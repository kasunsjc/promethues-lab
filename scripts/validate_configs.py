#!/usr/bin/env python3
"""Validate all additional configuration files added in the observability enhancement."""

import glob
import json
import os
import sys
import yaml

errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


# Validate Loki config YAML
try:
    with open("config/loki-config.yml") as f:
        cfg = yaml.safe_load(f)
    check("server" in cfg, "loki-config.yml: missing 'server' section")
    check("schema_config" in cfg, "loki-config.yml: missing 'schema_config' section")
    print("  \u2705 loki-config.yml is valid YAML")
except Exception as e:
    errors.append(f"loki-config.yml: {e}")

# Validate Promtail config YAML
try:
    with open("config/promtail-config.yml") as f:
        cfg = yaml.safe_load(f)
    check("clients" in cfg, "promtail-config.yml: missing 'clients' section")
    check("scrape_configs" in cfg, "promtail-config.yml: missing 'scrape_configs' section")
    print("  \u2705 promtail-config.yml is valid YAML")
except Exception as e:
    errors.append(f"promtail-config.yml: {e}")

# Validate OTel Collector config YAML
try:
    with open("config/otel-collector-config.yml") as f:
        cfg = yaml.safe_load(f)
    check("receivers" in cfg, "otel-collector-config.yml: missing 'receivers' section")
    check("exporters" in cfg, "otel-collector-config.yml: missing 'exporters' section")
    check("service" in cfg, "otel-collector-config.yml: missing 'service' section")
    print("  \u2705 otel-collector-config.yml is valid YAML")
except Exception as e:
    errors.append(f"otel-collector-config.yml: {e}")

# Validate BlackBox config YAML
try:
    with open("config/blackbox.yml") as f:
        cfg = yaml.safe_load(f)
    check("modules" in cfg, "blackbox.yml: missing 'modules' section")
    print("  \u2705 blackbox.yml is valid YAML")
except Exception as e:
    errors.append(f"blackbox.yml: {e}")

# Validate file_sd targets JSON
try:
    with open("config/file_sd/targets.json") as f:
        targets = json.load(f)
    check(isinstance(targets, list), "targets.json: must be a JSON array")
    for entry in targets:
        check(
            "targets" in entry and "labels" in entry,
            f"targets.json: each entry must have 'targets' and 'labels' keys, got: {entry}",
        )
    print(f"  \u2705 targets.json is valid ({len(targets)} target group(s))")
except Exception as e:
    errors.append(f"targets.json: {e}")

# Validate Grafana datasource provisioning files
ds_files = glob.glob("grafana/provisioning/datasources/*.yml")
for ds_path in ds_files:
    try:
        with open(ds_path) as f:
            cfg = yaml.safe_load(f)
        check("apiVersion" in cfg, f"{ds_path}: missing 'apiVersion'")
        check("datasources" in cfg, f"{ds_path}: missing 'datasources'")
        print(f"  \u2705 {os.path.basename(ds_path)} is valid")
    except Exception as e:
        errors.append(f"{ds_path}: {e}")

if errors:
    print("\n\u274c Validation errors:")
    for err in errors:
        print(f"  - {err}")
    sys.exit(1)

print("\n\u2705 All configuration files are valid")
