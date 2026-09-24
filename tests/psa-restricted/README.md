# PSA Restricted install check

Validates that `charts/openmetadata` can be installed into a namespace
that enforces the [Pod Security Standards "restricted"](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
profile, using two complementary policy engines.

## Engines

### `kind` — real K8s API server fidelity

Spins up a kind cluster whose API server runs the in-tree `PodSecurity`
admission plugin with `enforce=restricted:latest` cluster-wide (via an
`AdmissionConfiguration` mounted into the control-plane container — no
need to label namespaces individually).

For each scenario, renders the chart with `helm template`, applies it
with `kubectl apply --dry-run=server`, and parses stderr for `Warning:`
and `Forbidden`. **Limitation:** PSA only *enforces* at Pod creation; for
workload templates (Deployment, CronJob), violations show up as `Warning:`
rather than `Forbidden`. The harness counts both.

### `kyverno` — offline, autogen-rule coverage

Runs `kyverno apply` against the upstream PSS Restricted ClusterPolicy
bundle from `kyverno/policies@release-1.13`. Kyverno generates `autogen-*`
variants of each Pod-level rule for every workload kind (Deployment,
DaemonSet, CronJob, …), so it catches the same workload-template
violations as `Forbidden`, not just `Warning:` — useful in CI where you
want any non-compliant pod template to fail the build.

No cluster needed; runs in ~5s once policies are cached. Catches things
PSA's PodSecurity admission alone won't flag at apply time.

## Scenarios

| Scenario | Values | Expectation |
| --- | --- | --- |
| `baseline` | `values-baseline.yaml` — `omjobOperator.enabled=true`, no `securityContext` overrides | **fail** — must show violations. Regression catch in both directions. |
| `restricted` | `values-restricted.yaml` — full PSS-restricted `securityContext` on main + `omjobOperator` | **pass** — zero `Forbidden`/policy-fails. With `STRICT=1`, also zero `Warning:` (kind). |

## Run locally

```bash
# need: docker, kind, kubectl, helm, kyverno, git
bash scripts/test-psa-restricted.sh

# just one engine:
ENGINES=kind    bash scripts/test-psa-restricted.sh
ENGINES=kyverno bash scripts/test-psa-restricted.sh

# strict (kind engine fails on Warnings, not just Forbidden):
STRICT=1 bash scripts/test-psa-restricted.sh

# keep cluster around for poking:
KEEP_CLUSTER=1 bash scripts/test-psa-restricted.sh

# pin a different kyverno/policies ref:
KYVERNO_POLICIES_REF=release-1.14 bash scripts/test-psa-restricted.sh
```

Reports land in `./psa-report/`:

- `psa-report.md` — human-readable combined report (matrix table + per-cell detail)
- `psa-report.junit.xml` — `psa-restricted.<engine>` testcases, consumable by CI test reporters
- `<scenario>.manifest.yaml` — rendered chart per scenario (shared across engines)
- `kind.<scenario>.log` — raw `kubectl apply --dry-run=server` output
- `kyverno.<scenario>.log` — raw `kyverno apply` output

## CI

Wired up in `.github/workflows/psa-restricted.yml`. Runs on PRs that touch
the chart, the test fixtures, the script, or the workflow itself. Single
job runs both engines and emits a combined report into the job summary.
Kyverno policies are cached across runs via `actions/cache`.
