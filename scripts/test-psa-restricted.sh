#!/usr/bin/env bash
# Validate that charts/openmetadata can be installed under Pod Security Standards
# "restricted" by exercising two complementary engines and emitting a single
# combined report.
#
#   1. kind     — real K8s API server with PodSecurity admission enforcing
#                 restricted:latest cluster-wide. Apply rendered manifests with
#                 `kubectl apply --dry-run=server`; parse `Warning:` / `Forbidden`.
#   2. kyverno  — offline `kyverno apply` against the upstream Pod Security
#                 Standards restricted ClusterPolicy bundle (kyverno/policies).
#                 Catches workload-template autogen rules that PSA only
#                 enforces at actual Pod creation time.
#
# Both engines run per scenario; results are merged into psa-report/psa-report.md
# (plus per-engine raw logs and a JUnit XML).
#
# Exit codes:
#   0  every "pass"-expected scenario passes in every selected engine
#   1  at least one engine failed an expected-pass scenario, or an expected-fail
#      scenario stopped failing (regression detector)
#   2  setup error (missing tool, cluster create failed, policy fetch failed)
#
# Env vars:
#   ENGINES=kind,kyverno        comma list; default "kind,kyverno"
#   STRICT=1                    kind engine: fail on Warnings (default: only Forbidden)
#   KEEP_CLUSTER=1              don't delete the kind cluster on exit
#   KIND_NODE_IMAGE             override kindest/node image
#   KYVERNO_POLICIES_REF        git ref of kyverno/policies (default: release-1.13)
#   KYVERNO_POLICIES_CACHE      path to cached policies dir (default: ~/.cache/kyverno-policies)
#   REPORT_DIR                  where to write reports (default: ./psa-report)
#   CHART_DIR                   chart path (default: ./charts/openmetadata)

set -euo pipefail

CLUSTER=psa-test
NS=openmetadata
CHART_DIR="${CHART_DIR:-./charts/openmetadata}"
TESTS_DIR="tests/psa-restricted"
REPORT_DIR="${REPORT_DIR:-./psa-report}"
STRICT="${STRICT:-0}"
KEEP_CLUSTER="${KEEP_CLUSTER:-0}"
ENGINES="${ENGINES:-kind,kyverno}"
KYVERNO_POLICIES_REF="${KYVERNO_POLICIES_REF:-release-1.13}"
KYVERNO_POLICIES_CACHE="${KYVERNO_POLICIES_CACHE:-$HOME/.cache/kyverno-policies}"

declare -a SCENARIO_NAMES=(baseline restricted)
declare -A SCENARIO_FILES=(
  [baseline]="$TESTS_DIR/values-baseline.yaml"
  [restricted]="$TESTS_DIR/values-restricted.yaml"
)
declare -A SCENARIO_EXPECT=(
  [baseline]=fail
  [restricted]=pass
)

# Per-engine results: associative arrays keyed "<engine>:<scenario>"
declare -A RES_STATUS    # PASS / FAIL …
declare -A RES_W         # warnings/fail count (engine-defined)
declare -A RES_E         # errors/forbid count (engine-defined)
declare -A RES_DETAIL    # short detail block (markdown-ready)

need() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 2; }; }
need helm; need awk; need grep; need sed

mkdir -p "$REPORT_DIR"

cleanup() {
  if [[ "$KEEP_CLUSTER" != "1" ]] && command -v kind >/dev/null; then
    kind delete cluster --name "$CLUSTER" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# --- render all scenarios up front -------------------------------------------
for name in "${SCENARIO_NAMES[@]}"; do
  vfile="${SCENARIO_FILES[$name]}"
  manifest="$REPORT_DIR/$name.manifest.yaml"
  echo "==> rendering $name → $manifest"
  helm template om "$CHART_DIR" --namespace "$NS" -f "$vfile" > "$manifest" 2>/dev/null
done

# --- engine: kind -------------------------------------------------------------
run_engine_kind() {
  need kind; need kubectl
  if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    echo "==> [kind] creating cluster '$CLUSTER' with PSA restricted enforce"
    local kind_args=(--name "$CLUSTER" --config "$TESTS_DIR/kind-psa.yaml" --wait 60s)
    [[ -n "${KIND_NODE_IMAGE:-}" ]] && kind_args+=(--image "$KIND_NODE_IMAGE")
    kind create cluster "${kind_args[@]}" >&2
  fi

  local CTX="kind-$CLUSTER"
  kubectl --context "$CTX" create ns "$NS" --dry-run=client -o yaml | kubectl --context "$CTX" apply -f - >/dev/null

  for s in mysql-secrets:openmetadata-mysql-password \
           airflow-secrets:openmetadata-airflow-password \
           airflow-mysql-secrets:airflow-mysql-password; do
    local name="${s%%:*}"; local key="${s##*:}"
    kubectl --context "$CTX" -n "$NS" create secret generic "$name" \
      --from-literal="$key=stub" --dry-run=client -o yaml | \
      kubectl --context "$CTX" -n "$NS" apply -f - >/dev/null
  done

  for scenario in "${SCENARIO_NAMES[@]}"; do
    local manifest="$REPORT_DIR/$scenario.manifest.yaml"
    local applylog="$REPORT_DIR/kind.$scenario.log"
    set +e
    kubectl --context "$CTX" -n "$NS" apply -f "$manifest" --dry-run=server >"$applylog" 2>&1
    set -e

    local warn forbid
    warn=$(grep -c '^Warning:' "$applylog" || true)
    forbid=$(grep -c 'Forbidden' "$applylog" || true)

    local expect="${SCENARIO_EXPECT[$scenario]}"
    local status
    if [[ "$expect" == "pass" ]]; then
      if (( forbid > 0 )) || { [[ "$STRICT" == "1" ]] && (( warn > 0 )); }; then
        status="FAIL"
      else
        status="PASS"
      fi
    else
      if (( warn == 0 && forbid == 0 )); then
        status="FAIL (expected violations, got none)"
      else
        status="PASS (violations as expected)"
      fi
    fi

    RES_STATUS["kind:$scenario"]=$status
    RES_W["kind:$scenario"]=$warn
    RES_E["kind:$scenario"]=$forbid

    if (( warn + forbid > 0 )); then
      RES_DETAIL["kind:$scenario"]=$(grep -E '^(Warning:|Error from server \(Forbidden\))' "$applylog" \
        | sed -e 's/^Warning: would violate PodSecurity "[^"]*": /  warning: /' \
              -e 's/^Error from server (Forbidden): /  forbidden: /')
    fi
  done
}

# --- engine: kyverno ----------------------------------------------------------
ensure_kyverno_policies() {
  if [[ -d "$KYVERNO_POLICIES_CACHE/$KYVERNO_POLICIES_REF" ]]; then
    echo "==> [kyverno] using cached policies at $KYVERNO_POLICIES_CACHE/$KYVERNO_POLICIES_REF"
    return
  fi
  echo "==> [kyverno] fetching kyverno/policies@$KYVERNO_POLICIES_REF"
  mkdir -p "$KYVERNO_POLICIES_CACHE"
  local tmp; tmp=$(mktemp -d)
  git clone --depth=1 --branch "$KYVERNO_POLICIES_REF" \
    https://github.com/kyverno/policies.git "$tmp/repo" >/dev/null 2>&1 || {
      echo "failed to clone kyverno/policies@$KYVERNO_POLICIES_REF" >&2
      exit 2
    }
  mv "$tmp/repo" "$KYVERNO_POLICIES_CACHE/$KYVERNO_POLICIES_REF"
}

flatten_kyverno_policies() {
  local src="$KYVERNO_POLICIES_CACHE/$KYVERNO_POLICIES_REF/pod-security"
  local dst="$REPORT_DIR/kyverno-policies"
  rm -rf "$dst"; mkdir -p "$dst"
  /usr/bin/find "$src/restricted" "$src/baseline" -mindepth 2 -maxdepth 2 -name '*.yaml' | \
    while IFS= read -r f; do
      cp "$f" "$dst/"
    done
  echo "$dst"
}

run_engine_kyverno() {
  need kyverno; need git
  ensure_kyverno_policies
  local policy_dir; policy_dir=$(flatten_kyverno_policies)

  for scenario in "${SCENARIO_NAMES[@]}"; do
    local manifest="$REPORT_DIR/$scenario.manifest.yaml"
    local applylog="$REPORT_DIR/kyverno.$scenario.log"
    set +e
    kyverno apply "$policy_dir" --resource "$manifest" > "$applylog" 2>&1
    set -e

    # parse summary line: "pass: N, fail: N, warn: N, error: N, skip: N"
    local summary fails passes
    summary=$(grep -E '^pass:' "$applylog" | tail -1 || true)
    if [[ -z "$summary" ]]; then
      RES_STATUS["kyverno:$scenario"]="FAIL (kyverno apply produced no summary)"
      RES_W["kyverno:$scenario"]=0
      RES_E["kyverno:$scenario"]=0
      RES_DETAIL["kyverno:$scenario"]="kyverno output truncated; see kyverno.$scenario.log"
      continue
    fi
    fails=$(echo "$summary" | sed -E 's/.*fail: ([0-9]+).*/\1/')
    passes=$(echo "$summary" | sed -E 's/.*pass: ([0-9]+).*/\1/')

    local expect="${SCENARIO_EXPECT[$scenario]}"
    local status
    if [[ "$expect" == "pass" ]]; then
      if (( fails > 0 )); then
        status="FAIL"
      else
        status="PASS"
      fi
    else
      if (( fails == 0 )); then
        status="FAIL (expected violations, got none)"
      else
        status="PASS (violations as expected)"
      fi
    fi

    RES_STATUS["kyverno:$scenario"]=$status
    RES_W["kyverno:$scenario"]=$passes
    RES_E["kyverno:$scenario"]=$fails

    if (( fails > 0 )); then
      # show first ~10 unique failure rules
      RES_DETAIL["kyverno:$scenario"]=$(grep -E '^policy ' "$applylog" | head -10 | sed 's/^/  /')
    fi
  done
}

# --- run selected engines -----------------------------------------------------
IFS=',' read -ra engine_list <<< "$ENGINES"
for e in "${engine_list[@]}"; do
  case "$e" in
    kind)    run_engine_kind ;;
    kyverno) run_engine_kyverno ;;
    *) echo "unknown engine: $e" >&2; exit 2 ;;
  esac
done

# --- combined report ----------------------------------------------------------
report="$REPORT_DIR/psa-report.md"
junit="$REPORT_DIR/psa-report.junit.xml"
overall_fail=0

{
  echo "# PSA Restricted install check"
  echo
  echo "Chart: \`$CHART_DIR\`  •  Engines: \`$ENGINES\`  •  Generated: \`$(date -u +%FT%TZ)\`"
  echo
  echo "## Result matrix"
  echo
  printf "| scenario |"
  for e in "${engine_list[@]}"; do printf " %s |" "$e"; done
  echo
  printf "| --- |"
  for _ in "${engine_list[@]}"; do printf " --- |"; done
  echo
  for s in "${SCENARIO_NAMES[@]}"; do
    printf "| \`%s\` |" "$s"
    for e in "${engine_list[@]}"; do
      printf " %s |" "${RES_STATUS[$e:$s]:-—}"
    done
    echo
  done
  echo
} > "$report"

junit_cases=""
for s in "${SCENARIO_NAMES[@]}"; do
  for e in "${engine_list[@]}"; do
    status="${RES_STATUS[$e:$s]:-—}"
    {
      echo "### \`$e\` × \`$s\` — $status"
      echo
      if [[ "$e" == kind ]]; then
        echo "- warnings: **${RES_W[$e:$s]:-0}**, forbidden: **${RES_E[$e:$s]:-0}**"
      else
        echo "- policy-rule passes: **${RES_W[$e:$s]:-0}**, fails: **${RES_E[$e:$s]:-0}**"
      fi
      if [[ -n "${RES_DETAIL[$e:$s]:-}" ]]; then
        echo
        echo "<details><summary>detail</summary>"
        echo
        echo '```'
        echo "${RES_DETAIL[$e:$s]}"
        echo '```'
        echo
        echo "</details>"
      fi
      echo
    } >> "$report"

    # JUnit
    case_xml="<testcase classname=\"psa-restricted.$e\" name=\"$s\" time=\"0\">"
    if [[ "$status" == FAIL* ]]; then
      overall_fail=1
      body=$(echo "${RES_DETAIL[$e:$s]:-$status}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
      case_xml+="<failure message=\"$status\">${body}</failure>"
    fi
    case_xml+="</testcase>"
    junit_cases+="$case_xml"
  done
done

{
  echo "## Summary"
  echo
  echo "- overall: $([[ $overall_fail -eq 0 ]] && echo PASS || echo FAIL)"
} >> "$report"

{
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<testsuite name=\"psa-restricted\" tests=\"$((${#SCENARIO_NAMES[@]} * ${#engine_list[@]}))\" failures=\"$overall_fail\">"
  echo "$junit_cases"
  echo "</testsuite>"
} > "$junit"

echo
echo "==> report: $report"
echo "==> junit:  $junit"

exit $overall_fail
