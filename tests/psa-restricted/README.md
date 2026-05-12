# PSA Restricted install check

Validates that `charts/openmetadata` can be installed into a namespace
that enforces the [Pod Security Standards "restricted"](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
profile.

## What it does

For each scenario in `values-*.yaml`:

1. Render the chart with `helm template … -f <values>.yaml`.
2. Apply the rendered manifest with `kubectl apply --dry-run=server` against a
   kind cluster whose API server enforces `restricted:latest` cluster-wide.
3. Parse stderr for `Warning:` and `Forbidden` from the PodSecurity admission
   plugin, group by resource, and emit a markdown + JUnit report.

The kind cluster gets the PSA cluster-wide default via an
`AdmissionConfiguration` mounted into the control-plane container, so we don't
have to remember to label every namespace.

## Scenarios

| Scenario | Values | Expectation |
| --- | --- | --- |
| `baseline` | `values-baseline.yaml` — `omjobOperator.enabled=true`, no securityContext | **fail** — must show PSA violations. Regression catch: if this starts passing, either the chart has tightened defaults or PSA has loosened, either way worth knowing. |
| `restricted` | `values-restricted.yaml` — full PSS-restricted securityContext on main + omjobOperator | **pass** — zero `Forbidden`. With `STRICT=1`, also zero `Warning:`. |

## Run locally

```bash
# need: docker, kind, kubectl, helm
bash scripts/test-psa-restricted.sh

# strict (fail on Warnings, not just Forbidden):
STRICT=1 bash scripts/test-psa-restricted.sh

# keep cluster around for poking:
KEEP_CLUSTER=1 bash scripts/test-psa-restricted.sh
```

Reports land in `./psa-report/`:

- `psa-report.md` — human-readable
- `psa-report.junit.xml` — for CI test reporters
- `<scenario>.manifest.yaml` — rendered chart per scenario
- `<scenario>.apply.log` — raw `kubectl apply --dry-run=server` output

## CI

Wired up in `.github/workflows/psa-restricted.yml`. Runs on PRs that touch
the chart, the test fixtures, the script, or the workflow itself. Matrix
runs three kindest/node minor versions in parallel to catch PSS-version
drift early.
