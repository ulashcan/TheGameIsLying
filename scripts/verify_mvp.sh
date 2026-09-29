#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DEST:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"
SCHEME="TheGameIsLying"
PROJECT="TheGameIsLying.xcodeproj"
RUN_UI="${RUN_UI:-0}"

echo "=== VERIFY MVP ==="
echo "Destination: $DEST"

echo
echo "=== CLEAN ==="
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -destination "$DEST" -quiet

echo
echo "=== UNIT TESTS ==="
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -only-testing:TheGameIsLyingTests \
  2>&1 | tee /tmp/tgil-verify-unit.log | tail -20

if ! grep -q "TEST SUCCEEDED" /tmp/tgil-verify-unit.log; then
  echo "UNIT TESTS: FAIL"
  exit 1
fi
echo "UNIT TESTS: PASS"

if [[ "$RUN_UI" == "1" ]]; then
  echo
  echo "=== UI TESTS ==="
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DEST" \
    -only-testing:TheGameIsLyingUITests \
    2>&1 | tee /tmp/tgil-verify-ui.log | tail -20
  if ! grep -q "TEST SUCCEEDED" /tmp/tgil-verify-ui.log; then
    echo "UI TESTS: FAIL"
    exit 1
  fi
  echo "UI TESTS: PASS"
fi

echo
echo "=== RESULT: PASS ==="
