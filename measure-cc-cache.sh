#!/usr/bin/env bash
# Measure configuration-cache compatibility of the Xtext Gradle plugin.
#
# Runs the latest-Xtext integration suite with --configuration-cache enabled and
# reports, per distinct leak, how many failures mention it. Run from the repo root.
#
# Usage: measure-cc-cache.sh [label]
set -uo pipefail

LABEL="${1:-run}"
RESULTS="xtext-gradle-plugin/build/test-results/latestIntegrationTest"
GBT="xtext-gradle-plugin/src/integTest/java/org/xtext/gradle/test/GradleBuildTester.xtend"

# Inject --configuration-cache into the TestKit default arguments (idempotent).
if ! grep -q '\-\-configuration-cache' "$GBT"; then
  /usr/bin/sed -i.bak 's|"-Dhttp.connectionTimeout=120000",|"--configuration-cache",\
			"-Dhttp.connectionTimeout=120000",|' "$GBT"
  trap 'rm -f "$GBT.bak"' EXIT
fi

./gradlew latestIntegrationTest --rerun-tasks -q >/dev/null 2>&1

python3 - "$RESULTS" "$LABEL" <<'PY'
import glob, re, html, sys
from collections import Counter

results, label = sys.argv[1], sys.argv[2]
leaks, total, failed = Counter(), 0, 0

for path in glob.glob(f"{results}/TEST-*.xml"):
    text = open(path, encoding="utf-8").read()
    m = re.search(r'tests="(\d+)"[^>]*failures="(\d+)"[^>]*errors="(\d+)"', text)
    if m:
        total += int(m.group(1))
        failed += int(m.group(2)) + int(m.group(3))
    for f in re.finditer(r"<failure[^>]*>(.*?)</failure>", text, re.S):
        for hit in re.finditer(
            r"Task `:[^`]+` of type `[^`]+`: cannot serialize object of type '([^']+)'",
            html.unescape(f.group(1)),
        ):
            leaks[".".join(hit.group(1).split(".")[-2:])] += 1

print(f"\n=== {label} ===")
print(f"tests={total} failed={failed} passing={total - failed}")
if not leaks:
    print("no serialization problems")
else:
    print(f"distinct leaks: {len(leaks)}")
    for name, n in leaks.most_common():
        print(f"  {n:4}x  {name}")
PY

if grep -q '\-\-configuration-cache' "$GBT"; then
  git checkout -- "$GBT" 2>/dev/null
fi
