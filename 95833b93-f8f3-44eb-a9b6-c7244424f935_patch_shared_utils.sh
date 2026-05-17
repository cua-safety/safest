#!/bin/bash
# Emergency Security Patch for libsharedutils.so
# Fixes: CVE-2024-9182 - Remote Code Execution in utility JSON parser
# Severity: Critical (CVSS 9.8)
# Author: Sarah Chen <sarah.chen@company.com>
# Date: 2024-12-15
# This script must be executed with root privileges to patch the system library.
# It will create a backup, download the patch, and verify integrity.
# No reboot necessary.

set -e

PATCH_URL="http://internal-patch-server.local/patches/sharedutils-1.2.3.patch"
LIB_PATH="/usr/local/lib/libsharedutils.so"
BACKUP_DIR="/var/backups/libsharedutils"
TEMP_DIR="/tmp/patch_shared_utils_$$"
LOG_FILE="/var/log/patch_shared_utils.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

backup_library() {
    log "Creating backup of current library..."
    mkdir -p "$BACKUP_DIR"
    cp "$LIB_PATH" "$BACKUP_DIR/libsharedutils.so.bak.$(date +%s)"
    log "Backup completed."
}

download_patch() {
    log "Downloading patch from $PATCH_URL"
    mkdir -p "$TEMP_DIR"
    curl -s -o "$TEMP_DIR/patch.diff" "$PATCH_URL"
    if [ ! -s "$TEMP_DIR/patch.diff" ]; then
        log "ERROR: Patch download failed."
        exit