# Orderflow — Helm on Kubernetes, End to End

A hands-on reference project for learning and demonstrating production Helm patterns: chart authoring from scratch, subcharts, hooks, debugging, upgrade/rollback safety, and CI/CD — built around two real microservices instead of toy nginx examples.

## What this is

Two services deployed and operated entirely through Helm:

| Service | Stack | Role |
|---|---|---|
| `order-api` | Java 21 / Spring Boot | Public HTTP API. Calls `pricing-svc` to price orders. |
| `pricing-svc` | Python 3.12 / FastAPI | Internal service. Computes prices, persists SKU overrides to Postgres. |
| `postgresql` | Bitnami subchart | Backing store, pulled in as a conditional Helm dependency. |

Both charts are hand-written (not `helm create` scaffolds), wired together under an umbrella chart, and exercised through a deliberate break-and-fix lab covering the failure modes you actually hit in production: immutable selectors, dropped config, stuck upgrades, OOMKilled pods, PDBs blocking node drains, and more.

## Why it exists

Most Helm tutorials stop at "here's a Deployment template." This project goes further — deployment internals, hook lifecycle, the three-way merge, release Secret internals, and a structured debugging funnel — so that reading a `helm upgrade` failure in production becomes a five-minute diagnosis instead of a guessing exercise.

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Docker | latest | Image builds + local cluster runtime |
| kind | latest | Local multi-node Kubernetes |
| kubectl | matching cluster | |
| Helm | 3.14+ | Note: Helm 4 requires `--verify=false` for unsigned community plugins |
| helm-diff plugin | latest | `helm plugin install https://github.com/databus23/helm-diff --verify=false` |
| helm-unittest plugin | latest | `helm plugin install https://github.com/helm-unittest/helm-unittest --verify=false` |
| jq | latest | Inspecting release Secrets and JSON output |
| Java 21 + Maven | | Building `order-api` |
| Python 3.12 | | Local testing of `pricing-svc` |

> **Windows / Git Bash users:** plugin installers may require PowerShell 7 (`pwsh`) on PATH. See `docs/troubleshooting.md` if `helm plugin install` fails with `exec: "pwsh": executable file not found`.

## Project structure