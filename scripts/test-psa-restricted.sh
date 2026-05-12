#!/usr/bin/env bash
# Render the openmetadata chart for each scenario in tests/psa-restricted/,
# pipe it through `kubectl apply --dry-run=server` against a kind cluster
# whose API server enforces Pod Security Standards "restricted" cluster-wide,
# and emit a markdown report + JUnit XML.
#
# Exit codes:
#   0  no Forbidden, optionally no Warnings (see STRICT)
#   1  at least one Forbidden in any non-baseline scenario
#   2  setup error (kind/helm/kubectl missing, cluster create failed, etc.)
#
# Env vars:
#   STRICT=1            also fail on Warnings (default: only fail on Forbidden)
#   KEEP_CLUSTER=1      don't delete the kind cluster on exit
#   KIND_NODE_IMAGE     override kindest/node image (default: kind's bundled)
#   REPORT_DIR          where to write reports (default: ./psa-report)
#   CHART_DIR           chart path (default: ./charts/openmetadata)

set -euo pipefail

CLUSTER=psa-test
NS=openmetadata
CHART_DIR="${CHART_DIR:-./charts/openmetadata}"
TESTS_DIR="tests/psa-restricted"
REPORT_DIR="${REPORT_DIR:-./psa-report}"
STRICT="${STRICT:-0}"
KEEP_CLUSTER="${KEEP_CLUSTER:-0}"

# Scenario name → values file. Baseline is expected to fail (regression catch).
declare -a SCENARIO_NAMES=(baseline restricted)
declare -A SCENARIO_FILES=(
  [baseline]="$TESTS_DIR/values-baseline.yaml"
  [restricted]="$TESTS_DIR/values-restricted.yaml"
)
declare -A SCENARIO_EXPECT=(
  [baseline]=fail      # expected: PSA violations exist (proves test harness works)
  [restricted]=pass    # expected: no violations
)

need() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 2; }; }
need kind; need kubectl; need helm; need awk; need grep

mkdir -p "$REPORT_DIR"

cleanup() {
  if [[ "$KEEP_CLUSTER" != "1" ]]; then
    kind delete cluster --name "$CLUSTER" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# --- cluster setup ------------------------------------------------------------
if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "==> creating kind cluster '$CLUSTER' with PSA restricted enforce"
  kind_args=(--name "$CLUSTER" --config "$TESTS_DIR/kind-psa.yaml" --wait 60s)
  [[ -n "${KIND_NODE_IMAGE:-}" ]] && kind_args+=(--image "$KIND_NODE_IMAGE")
  kind create cluster "${kind_args[@]}" >&2
fi

CTX="kind-$CLUSTER"
kubectl --context "$CTX" create ns "$NS" --dry-run=client -o yaml | kubectl --context "$CTX" apply -f - >/dev/null

# stub secrets so chart renders fully (passwords don't matter for dry-run)
for s in mysql-secrets:openmetadata-mysql-password \
         airflow-secrets:openmetadata-airflow-password \
         airflow-mysql-secrets:airflow-mysql-password; do
  name="${s%%:*}"; key="${s##*:}"
  kubectl --context "$CTX" -n "$NS" create secret generic "$name" \
    --from-literal="$key=stub" --dry-run=client -o yaml | \
    kubectl --context "$CTX" -n "$NS" apply -f - >/dev/null
done

# --- per-scenario run ---------------------------------------------------------
fail=0
report="$REPORT_DIR/psa-report.md"
junit="$REPORT_DIR/psa-report.junit.xml"

{
  echo "# PSA Restricted install check"
  echo
  echo "Chart: \`$CHART_DIR\`  •  Cluster PSA: \`enforce=restricted:latest\`  •  Generated: \`$(date -u +%FT%TZ)\`"
  echo
} > "$report"

junit_cases=""
total_warn=0; total_forbid=0

for name in "${SCENARIO_NAMES[@]}"; do
  vfile="${SCENARIO_FILES[$name]}"
  expect="${SCENARIO_EXPECT[$name]}"
  echo "==> scenario: $name  (values=$vfile, expect=$expect)"

  manifest="$REPORT_DIR/$name.manifest.yaml"
  applylog="$REPORT_DIR/$name.apply.log"

  helm template om "$CHART_DIR" --namespace "$NS" -f "$vfile" > "$manifest" 2>/dev/null

  set +e
  kubectl --context "$CTX" -n "$NS" apply -f "$manifest" --dry-run=server >"$applylog" 2>&1
  set -e

  warn=$(grep -c '^Warning:' "$applylog" || true)
  forbid=$(grep -c 'Forbidden' "$applylog" || true)
  total_warn=$((total_warn + warn))
  total_forbid=$((total_forbid + forbid))

  # determine pass/fail per scenario
  if [[ "$expect" == "pass" ]]; then
    if (( forbid > 0 )) || { [[ "$STRICT" == "1" ]] && (( warn > 0 )); }; then
      status="FAIL"; fail=1
    else
      status="PASS"
    fi
  else
    # baseline: we *expect* violations; treat absence of any as suspicious
    if (( warn == 0 && forbid == 0 )); then
      status="FAIL (expected violations, got none — chart may have changed)"
      fail=1
    else
      status="PASS (violations present as expected)"
    fi
  fi

  {
    echo "## Scenario: \`$name\`  —  $status"
    echo
    echo "- values: \`$vfile\`"
    echo "- expectation: \`$expect\`"
    echo "- warnings: **$warn**"
    echo "- forbidden: **$forbid**"
    echo
    if (( warn + forbid > 0 )); then
      echo "<details><summary>violation detail</summary>"
      echo
      echo '```'
      grep -E '^(Warning:|Error from server \(Forbidden\))' "$applylog" | sed -e 's/^Warning: would violate PodSecurity "[^"]*": /  warning: /' || true
      echo '```'
      echo
      echo "</details>"
      echo
    fi
  } >> "$report"

  # JUnit case
  case_xml="<testcase classname=\"psa-restricted\" name=\"$name\" time=\"0\">"
  if [[ "$status" == FAIL* ]]; then
    body=$(grep -E '^(Warning:|Error from server \(Forbidden\))' "$applylog" | head -20 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    case_xml+="<failure message=\"$status\">${body}</failure>"
  fi
  case_xml+="</testcase>"
  junit_cases+="$case_xml"
done

{
  echo "## Summary"
  echo
  echo "- total warnings: **$total_warn**"
  echo "- total forbidden: **$total_forbid**"
  echo "- overall: $([[ $fail -eq 0 ]] && echo PASS || echo FAIL)"
} >> "$report"

{
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<testsuite name=\"psa-restricted\" tests=\"${#SCENARIO_NAMES[@]}\" failures=\"$([[ $fail -eq 0 ]] && echo 0 || echo 1)\">"
  echo "$junit_cases"
  echo "</testsuite>"
} > "$junit"

echo
echo "==> report: $report"
echo "==> junit:  $junit"

exit $fail
