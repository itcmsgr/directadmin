#!/bin/bash
# SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
# ITCMS.GR Free License – All Rights Reserved
# Copyright (c) 2025 Antonios Voulvoulis
#
################################################################################
# all_pre.sh - DirectAdmin Global Pre-Hook for DNS Changes
#
# Description:
#   This is a DirectAdmin global pre-hook that intercepts CMD_DNS_ADMIN
#   and CMD_DNS_CONTROL actions before they modify DNS zones. It creates
#   a backup of the current DNS zone file to enable diff comparison in
#   the post-hook.
#
# DirectAdmin Hook Location:
#   /usr/local/directadmin/scripts/custom/all_pre.sh
#
# Environment Variables (provided by DirectAdmin):
#   $command  - The DA command being executed (e.g., CMD_DNS_ADMIN)
#   $action   - The action being performed (e.g., save, add, delete)
#   $domain   - The domain being modified
#   $username - The user performing the action
#
# NIS2 Compliance:
#   This hook supports audit trail requirements under NIS2 Directive
#   (EU) 2022/2555 by preserving DNS zone state before modifications.
#
# Author: Antonios Voulvoulis
# Contact: contact@itcms.gr
# Website: https://itcms.gr
#
################################################################################

set -euo pipefail

# Configuration
ZONE_DIR="${ZONE_DIR:-/var/named}"
BACKUP_DIR="${DNS_BACKUP_DIR:-/var/local/da_dns_backups}"
LOG_FILE="${DNS_HOOK_LOG:-/var/log/da-hooks/dns_backup.log}"
MAX_BACKUP_AGE_DAYS="${DNS_BACKUP_RETENTION:-7}"

# Ensure backup and log directories exist
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# Logging function
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Error logging
log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOG_FILE" >&2
}

# Main logic
main() {
    # Check if this is a DNS modification command
    if [[ "${command:-}" != "CMD_DNS_ADMIN" ]] && [[ "${command:-}" != "CMD_DNS_CONTROL" ]]; then
        # Not a DNS command, exit silently
        exit 0
    fi

    # Check if this is a save/modify action
    if [[ "${action:-}" != "save" ]] && [[ "${action:-}" != "edit" ]]; then
        # Not a save action, exit silently
        exit 0
    fi

    # Validate that we have a domain
    if [[ -z "${domain:-}" ]]; then
        log_error "No domain specified in DNS modification command"
        exit 0  # Don't block the operation
    fi

    local zone_file="${ZONE_DIR}/${domain}.db"

    # Check if zone file exists
    if [[ ! -f "$zone_file" ]]; then
        log_message "Zone file does not exist yet for domain: $domain (possibly new zone)"
        exit 0
    fi

    # Create timestamped backup
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/${domain}.${timestamp}.db"

    # Copy the current zone file
    if cp "$zone_file" "$backup_file"; then
        log_message "Backed up DNS zone for $domain: $backup_file (command: $command, action: $action, user: ${username:-unknown})"

        # Store backup path for post-hook
        echo "$backup_file" > "${BACKUP_DIR}/${domain}.last_backup"

        # Clean up old backups (older than MAX_BACKUP_AGE_DAYS)
        find "$BACKUP_DIR" -name "${domain}.*.db" -type f -mtime "+${MAX_BACKUP_AGE_DAYS}" -delete 2>/dev/null || true

        log_message "Cleaned up old backups for $domain (retention: ${MAX_BACKUP_AGE_DAYS} days)"
    else
        log_error "Failed to backup DNS zone for $domain"
    fi

    exit 0
}

# Execute main function
main "$@"
