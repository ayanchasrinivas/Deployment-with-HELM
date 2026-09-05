# Orderflow — Helm on Kubernetes, End to End
<img width="739" height="380" alt="images (2)" src="https://github.com/user-attachments/assets/facf8e03-ee2f-4cbb-8d42-1446852f92ac" />

A hands-on project on production Helm patterns and practices: chart authoring from scratch, subcharts, hooks, debugging, upgrade/rollback safety, and CI/CD — built around two real microservices.

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
orderflow/
├── README.md
├── kind-config.yaml                          # 3+ node local cluster definition
├── Makefile                                  # standardised lint/diff/deploy/test/rollback targets
│
├── services/
│   ├── order-api/                            # Java / Spring Boot
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/
│   │   │   │   │   └── com/
│   │   │   │   │       └── orderflow/
│   │   │   │   │           ├── OrderApiApplication.java
│   │   │   │   │           └── OrderController.java
│   │   │   │   └── resources/
│   │   │   │       └── application.yaml
│   │   ├── pom.xml
│   │   └── Dockerfile
│   │
│   └── pricing-svc/                          # Python / FastAPI
│       ├── app/
│       │   └── main.py
│       ├── migrations/
│       │   └── 001_init.sql
│       ├── requirements.txt
│       └── Dockerfile
│
├── charts/
│   ├── order-api/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── serviceaccount.yaml
│   │       ├── ingress.yaml
│   │       └── NOTES.txt
│   │
│   ├── pricing-svc/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values.schema.json
│   │   ├── tests/
│   │   │   └── deployment_test.yaml          # helm-unittest
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── configmap.yaml
│   │       ├── secret.yaml
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── serviceaccount.yaml
│   │       ├── hpa.yaml
│   │       ├── pdb.yaml
│   │       ├── migration-job.yaml            # pre-install/pre-upgrade hook
│   │       ├── backup-job.yaml                # pre-upgrade hook
│   │       ├── NOTES.txt
│   │       └── tests/
│   │           └── test-api.yaml              # helm test
│   │
│   └── orderflow/                             # umbrella chart
│       ├── Chart.yaml                         # declares order-api, pricing-svc, postgresql
│       ├── Chart.lock                         # committed — pins resolved dependency versions
│       ├── values.yaml
│       └── charts/                            # populated by `helm dependency update`
│
├── envs/
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   └── values-prod.yaml
│
├── .github/
│   └── workflows/
│       └── deploy.yaml                        # lint → unittest → diff → deploy → smoke test
│
└── docs/
    ├── debugging.md                           # the six-stage debugging funnel
    ├── break-it-lab.md                        # 10 guided failure scenarios
    └── troubleshooting.md                     # environment/tooling gotchas (Windows, plugins, etc.)

## Common operations

```bash
make lint              # helm lint + helm unittest
make template          # render locally, no cluster contact
make diff               # preview changes before touching prod
make deploy             # atomic upgrade --install
make test                # helm test --logs
make rollback           # helm rollback to last good revision
```

Debugging a stuck or failed release:

```bash
helm status orderflow -n orderflow-dev --show-resources
helm get values orderflow -n orderflow-dev --all
helm get manifest orderflow -n orderflow-dev | kubectl diff -f -
kubectl get events -n orderflow-dev --sort-by='.lastTimestamp' | tail -30
```
