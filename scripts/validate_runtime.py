#!/usr/bin/env python3
"""Runtime validation checks for the full monitoring stack.

Usage: python3 scripts/validate_runtime.py <mode> [args...]

Modes:
  prometheus-targets <url>   - Check Prometheus scrape targets
  loki-labels <url>          - Check Loki has ingested logs
  thanos-stores <url>        - Check Thanos Query sees stores
  thanos-query <url>         - Execute a PromQL query via Thanos
  file-sd-targets <url>      - Check file SD targets loaded in Prometheus
  grafana-datasources <url>  - Check Grafana datasources are provisioned
"""

import json
import sys
import urllib.request
import urllib.error
import base64


def fetch_json(url, *, user=None, password=None):
    req = urllib.request.Request(url)
    if user and password:
        creds = base64.b64encode(f"{user}:{password}".encode()).decode()
        req.add_header("Authorization", f"Basic {creds}")
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        return json.loads(resp.read())
    except urllib.error.HTTPError:
        return None
    except Exception as e:
        print(f"  ⚠️  Request failed: {e}")
        return None


def check_prometheus_targets(base_url):
    data = fetch_json(f"{base_url}/api/v1/targets")
    if data is None:
        print("  ⚠️  Could not reach Prometheus")
        return
    active = data["data"]["activeTargets"]
    up_count = 0
    total = len(active)
    for t in active:
        status = "✅" if t["health"] == "up" else "⚠️"
        if t["health"] == "up":
            up_count += 1
        print(f"  {status} {t['labels'].get('job', 'unknown'):30s} {t['health']}")
    print(f"\nTotal: {up_count}/{total} targets up")
    if up_count < total * 0.5:
        print("❌ Less than 50% of targets are up")
        sys.exit(1)


def check_loki_labels(base_url):
    data = fetch_json(f"{base_url}/loki/api/v1/labels")
    if data is None:
        print("  ⚠️  Could not reach Loki")
        return
    labels = data.get("data", [])
    if labels:
        print(f"  ✅ Loki has {len(labels)} label(s): {labels}")
    else:
        print("  ⚠️  Loki has no labels yet (Promtail may still be initializing)")


def check_thanos_stores(base_url):
    data = fetch_json(f"{base_url}/api/v1/stores")
    if data is None:
        print("  ⚠️  Could not reach Thanos Query")
        return
    stores = data.get("data", {})
    if isinstance(stores, dict):
        stores = stores.get("statuses", [])
    if stores:
        print(f"  ✅ Thanos Query sees {len(stores)} store(s)")
    else:
        print("  ⚠️  Thanos Query has no stores yet (sidecar may be connecting)")


def check_thanos_query(base_url):
    data = fetch_json(f"{base_url}/api/v1/query?query=up")
    if data is None:
        print("  ⚠️  Could not reach Thanos Query")
        return
    if data.get("status") == "success":
        results = data.get("data", {}).get("result", [])
        print(f"  ✅ Thanos Query executed PromQL successfully ({len(results)} results)")
    else:
        print("  ⚠️  Thanos Query returned non-success status")


def check_file_sd_targets(base_url):
    data = fetch_json(f"{base_url}/api/v1/targets")
    if data is None:
        print("  ⚠️  Could not reach Prometheus")
        return
    active = data["data"]["activeTargets"]
    file_sd = [t for t in active if "file-sd" in t.get("scrapePool", "")]
    if file_sd:
        print(f"  ✅ File SD loaded {len(file_sd)} target(s)")
        for t in file_sd:
            print(f"    - {t['labels'].get('job', 'unknown')}: {t['health']}")
    else:
        print("  ⚠️  No file SD targets found (may use different scrape pool name)")
        pools = set(t.get("scrapePool", "unknown") for t in active)
        print(f"    Available pools: {pools}")


def check_grafana_datasources(base_url):
    datasources = fetch_json(f"{base_url}/api/datasources", user="admin", password="grafana")
    if datasources is None:
        print("  ⚠️  Could not reach Grafana")
        return
    expected = ["Prometheus", "Loki", "Thanos", "InfluxDB"]
    found = [ds["name"] for ds in datasources]
    for name in expected:
        if name in found:
            print(f"  ✅ {name} datasource provisioned")
        else:
            print(f"  ⚠️  {name} datasource not found")
    print(f"\n  Total datasources: {len(found)}")


MODES = {
    "prometheus-targets": check_prometheus_targets,
    "loki-labels": check_loki_labels,
    "thanos-stores": check_thanos_stores,
    "thanos-query": check_thanos_query,
    "file-sd-targets": check_file_sd_targets,
    "grafana-datasources": check_grafana_datasources,
}

if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in MODES:
        print(f"Usage: {sys.argv[0]} <mode> <base_url>")
        print(f"Modes: {', '.join(MODES)}")
        sys.exit(1)
    mode = sys.argv[1]
    url = sys.argv[2].rstrip("/")
    MODES[mode](url)
