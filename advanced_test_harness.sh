#!/bin/bash
echo -e "\n=== STARTING ADVANCED ZERO-TRUST TEST BATTERY ==="

FAILURES=0
pass_or_fail() {
    if [ $1 -eq 0 ]; then echo -e "  [PASS] $2"; else echo -e "  [FAIL] $2"; ((FAILURES++)); fi
}

echo -e "\n--- TEST SUITE: audit_linux.sh ---"

# Test 1: JSON Export parsing validity
echo "> Testing JSON Export formatting (Linux)..."
rm -f logs/*.json
./audit_linux.sh --server-ip 8.8.8.8 --ping-count 1 --export-json > /dev/null 2>&1
JSON_FILE=$(ls logs/*.json 2>/dev/null | head -n 1)
if [[ -n "$JSON_FILE" ]]; then
    python3 -c "import json; json.load(open('$JSON_FILE'))" > /dev/null 2>&1
    pass_or_fail $? "JSON Output strictly parses as valid JSON (Linux)"
else
    pass_or_fail 1 "JSON Output strictly parses as valid JSON (Linux)"
fi
rm -f logs/*.json

# Test 2: Structural - Zero packets jitter calculation
echo "> Testing Division by Zero safety on 1 Ping (Linux)..."
./audit_linux.sh --server-ip 1.1.1.1 --ping-count 1 --no-log > /dev/null 2>&1
pass_or_fail $? "Single ping execution (No division by zero) (Linux)"

echo -e "\n--- TEST SUITE: audit_windows.ps1 ---"

# Test 3: JSON Export parsing validity (Windows)
echo "> Testing JSON Export formatting (Windows)..."
rm -f logs/*.json
pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -ServerIP 8.8.8.8 -PingCount 1 -ExportJson" > /dev/null 2>&1
JSON_FILE=$(ls logs/*.json 2>/dev/null | head -n 1)
if [[ -n "$JSON_FILE" ]]; then
    python3 -c "import json; json.load(open('$JSON_FILE'))" > /dev/null 2>&1
    pass_or_fail $? "JSON Output strictly parses as valid JSON (Windows)"
else
    pass_or_fail 1 "JSON Output strictly parses as valid JSON (Windows)"
fi
rm -f logs/*.json

# Test 4: Single Ping Execution (Windows)
echo "> Testing Jitter/Average safety on 1 Ping (Windows)..."
pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -ServerIP 1.1.1.1 -PingCount 1 -NoLog" > /dev/null 2>&1
pass_or_fail $? "Single ping execution (Windows)"

echo -e "\n=== ADVANCED TEST BATTERY COMPLETE ==="
echo "Total Failures: $FAILURES"
exit $FAILURES
