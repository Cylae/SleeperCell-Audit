#!/bin/bash
echo -e "\n=== STARTING EXTREME TEST BATTERY ==="

FAILURES=0
pass_or_fail() {
    if [ $1 -eq 0 ]; then echo -e "  [PASS] $2"; else echo -e "  [FAIL] $2"; ((FAILURES++)); fi
}

echo -e "\n--- TEST SUITE: audit_linux.sh ---"

# Test 1: Blackhole IP (100% Packet Loss / No Route)
echo "> Running Blackhole IP test (expecting timeouts but no crash)..."
./audit_linux.sh --server-ip 192.0.2.1 --ping-count 2 --no-log > /dev/null 2>&1
pass_or_fail $? "Blackhole IP Test (Linux)"

# Test 2: Invalid CLI Inputs (Fuzzing)
echo "> Running CLI Fuzzing (should exit 1)..."
./audit_linux.sh --server-ip 999.999.999.999 > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid IP Rejection"; else pass_or_fail 1 "Invalid IP Rejection"; fi

./audit_linux.sh --port 70000 > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid Port Rejection (Linux)"; else pass_or_fail 1 "Invalid Port Rejection (Linux)"; fi

./audit_linux.sh --ping-count 50 > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid Ping Count Rejection (Linux)"; else pass_or_fail 1 "Invalid Ping Count Rejection (Linux)"; fi

# Test 3: Corrupt Config File
echo "> Running Corrupt JSON Test (should fallback to defaults)..."
echo "{ corrupted: 'json', ]" > audit_config.json
./audit_linux.sh --no-log > /dev/null 2>&1
pass_or_fail $? "Corrupt JSON Fallback (Linux)"
rm audit_config.json

# Test 4: Headless Execution (No TTY)
echo "> Running Headless Execution Test (piped input)..."
echo "" | ./audit_linux.sh --no-log > /dev/null 2>&1
pass_or_fail $? "Headless Execution (Linux)"

echo -e "\n--- TEST SUITE: audit_windows.ps1 ---"

# Test 5: Blackhole IP (Windows)
echo "> Running Blackhole IP test..."
pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -ServerIP 192.0.2.1 -PingCount 2 -NoLog" > /dev/null 2>&1
pass_or_fail $? "Blackhole IP Test (Windows)"

# Test 6: Invalid CLI Inputs (Windows)
# Windows logic throws parameter validation error, which returns exit code 1
echo "> Running CLI Fuzzing..."
pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -ServerIP 999.999.999.999 -NoLog" > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid IP Fuzzing (Windows)"; else pass_or_fail 1 "Invalid IP Fuzzing (Windows)"; fi

pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -TargetPort 70000 -NoLog" > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid Port Fuzzing (Windows)"; else pass_or_fail 1 "Invalid Port Fuzzing (Windows)"; fi

pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -PingCount 50 -NoLog" > /dev/null 2>&1
res=$?; if [ $res -eq 1 ]; then pass_or_fail 0 "Invalid Ping Count Fuzzing (Windows)"; else pass_or_fail 1 "Invalid Ping Count Fuzzing (Windows)"; fi

# Test 7: Corrupt Config File (Windows)
echo "> Running Corrupt JSON Test (should fallback)..."
echo "{ corrupted: 'json', ]" > audit_config.json
pwsh -NonInteractive -NoProfile -Command "./audit_windows.ps1 -NoLog" > /dev/null 2>&1
pass_or_fail $? "Corrupt JSON Fallback (Windows)"
rm audit_config.json

echo -e "\n=== TEST BATTERY COMPLETE ==="
echo "Total Failures: $FAILURES"
exit $FAILURES
