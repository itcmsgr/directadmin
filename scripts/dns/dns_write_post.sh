#!/bin/bash
# SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
# ITCMS.GR Free License – All Rights Reserved
# Copyright (c) 2025 Antonios Voulvoulis
#
################################################################################
# dns_write_post.sh - DirectAdmin DNS Zone Write Post-Hook
#
# Description:
#   This post-hook executes after DirectAdmin writes a DNS zone file.
#   It compares the new zone with the backup created by all_pre.sh,
#   generates a unified diff, and emails the changes to the domain owner.
#
# DirectAdmin Hook Location:
#   /usr/local/directadmin/scripts/custom/dns_write_post.sh
#
# Environment Variables (provided by DirectAdmin):
#   $domain   - The domain that was modified
#   $username - The DA username (may be admin)
#
# Email Recipients (determined by script):
#   1. Domain owner's email from user.conf
#   2. Fallback to admin_email from directadmin.conf
#
# NIS2 Compliance:
#   Supports incident detection and audit requirements under NIS2 Directive
#   (EU) 2022/2555 by notifying domain owners of DNS changes immediately.
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
DA_CONF="${DA_CONF:-/usr/local/directadmin/conf/directadmin.conf}"
DA_DATA_DIR="${DA_DATA_DIR:-/usr/local/directadmin/data}"
DOMAIN_OWNERS="${DOMAIN_OWNERS:-/etc/virtual/domainowners}"
LOG_FILE="${DNS_HOOK_LOG:-/var/log/da-hooks/dns_notify.log}"
SEND_EMAIL="${DNS_SEND_EMAIL:-true}"
EMAIL_FROM="${DNS_EMAIL_FROM:-noreply@$(hostname -f)}"

# Email settings
MAX_DIFF_LINES="${DNS_MAX_DIFF_LINES:-500}"
EMAIL_SUBJECT_PREFIX="${DNS_EMAIL_SUBJECT_PREFIX:-[DNS ALERT]}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging functions
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOG_FILE" >&2
}

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >> "$LOG_FILE"
}

# Get domain owner username
get_domain_owner() {
    local domain="$1"

    if [[ -f "$DOMAIN_OWNERS" ]]; then
        grep "^${domain}:" "$DOMAIN_OWNERS" | cut -d: -f2 | tr -d ' ' || echo ""
    else
        echo ""
    fi
}

# Get user's email address
get_user_email() {
    local username="$1"
    local user_conf="${DA_DATA_DIR}/users/${username}/user.conf"

    if [[ -f "$user_conf" ]]; then
        grep -oP '(?<=^email=).*' "$user_conf" | tr -d ' \r\n' || echo ""
    else
        echo ""
    fi
}

# Get admin email as fallback
get_admin_email() {
    if [[ -f "$DA_CONF" ]]; then
        grep -oP '(?<=^admin_email=).*' "$DA_CONF" | tr -d ' \r\n' || echo "root@$(hostname -f)"
    else
        echo "root@$(hostname -f)"
    fi
}

# Determine recipient email
get_recipient_email() {
    local domain="$1"
    local owner
    owner=$(get_domain_owner "$domain")

    if [[ -n "$owner" ]]; then
        local owner_email
        owner_email=$(get_user_email "$owner")

        if [[ -n "$owner_email" ]]; then
            echo "$owner_email"
            return 0
        fi
    fi

    # Fallback to admin email
    get_admin_email
}

# Generate and send email with DNS diff
send_dns_change_notification() {
    local domain="$1"
    local backup_file="$2"
    local current_file="$3"
    local recipient_email="$4"
    local modified_by="${username:-unknown}"

    # Generate unified diff
    local diff_output
    if ! diff_output=$(diff -u "$backup_file" "$current_file" 2>&1); then
        # diff returns non-zero when files differ (expected)
        :
    fi

    # Check if there are actual changes (ignore SOA serial number changes only)
    local meaningful_changes
    meaningful_changes=$(echo "$diff_output" | grep -E '^[+-]' | grep -v '^[+-]{3}' | grep -vE '^\+.*\s+IN\s+SOA\s+' | grep -vE '^-.*\s+IN\s+SOA\s+' || true)

    if [[ -z "$meaningful_changes" ]]; then
        log_info "No meaningful DNS changes detected for $domain (only SOA serial update)"
        return 0
    fi

    # Truncate diff if too long
    local line_count
    line_count=$(echo "$diff_output" | wc -l)

    if [[ $line_count -gt $MAX_DIFF_LINES ]]; then
        diff_output=$(echo "$diff_output" | head -n "$MAX_DIFF_LINES")
        diff_output="$diff_output

... (diff truncated: $line_count lines total, showing first $MAX_DIFF_LINES)"
    fi

    # Get timestamp
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S %Z')

    # Build email body
    local email_body
    email_body=$(cat <<EOF
DNS Zone Change Notification
============================

DOMAIN:      $domain
MODIFIED BY: $modified_by
TIMESTAMP:   $timestamp
SERVER:      $(hostname -f)

SECURITY NOTICE:
If you did not authorize this change, please contact your hosting
administrator immediately. Unauthorized DNS changes may indicate
a security incident.

NIS2 COMPLIANCE:
This notification is part of your DNS infrastructure's audit trail,
supporting governance requirements under EU NIS2 Directive 2022/2555.

--------------------------------------------------------------------------------
DNS ZONE CHANGES (Unified Diff)
--------------------------------------------------------------------------------

Legend:
  Lines starting with '-' show REMOVED/OLD records
  Lines starting with '+' show ADDED/NEW records
  Unchanged lines provide context

$diff_output

--------------------------------------------------------------------------------

NEXT STEPS:
1. Review the changes above carefully
2. Verify all modifications are authorized
3. Update your documentation if needed
4. Report any suspicious changes immediately

For questions or concerns, contact your hosting provider.

---
Generated by DirectAdmin DNS Change Monitor
ITCMS DNS Alert System - https://itcms.gr
Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
EOF
)

    # Send email
    local email_subject="${EMAIL_SUBJECT_PREFIX} DNS Changes for ${domain}"

    if command -v mail &> /dev/null; then
        # Use 'mail' command if available
        echo "$email_body" | mail -s "$email_subject" -r "$EMAIL_FROM" "$recipient_email"
        log_message "Notification sent via 'mail' to $recipient_email for domain $domain"
    elif command -v sendmail &> /dev/null; then
        # Fallback to sendmail
        {
            echo "From: DNS Alert System <${EMAIL_FROM}>"
            echo "To: ${recipient_email}"
            echo "Subject: ${email_subject}"
            echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            echo "$email_body"
        } | sendmail -t -f "$EMAIL_FROM"
        log_message "Notification sent via 'sendmail' to $recipient_email for domain $domain"
    else
        log_error "No mail command available (tried 'mail' and 'sendmail')"
        # Save notification to file as fallback
        local fallback_file="/var/local/da_dns_backups/notifications/${domain}_${timestamp//[: ]/_}.txt"
        mkdir -p "$(dirname "$fallback_file")"
        echo "$email_body" > "$fallback_file"
        log_message "Notification saved to file: $fallback_file (no mailer available)"
    fi
}

# Main logic
main() {
    # Validate domain variable
    if [[ -z "${domain:-}" ]]; then
        log_error "No domain specified in dns_write_post hook"
        exit 0
    fi

    log_info "DNS write post-hook triggered for domain: $domain"

    # Check if email sending is enabled
    if [[ "$SEND_EMAIL" != "true" ]]; then
        log_info "Email notifications disabled (DNS_SEND_EMAIL=$SEND_EMAIL)"
        exit 0
    fi

    # Get backup file path
    local backup_marker="${BACKUP_DIR}/${domain}.last_backup"

    if [[ ! -f "$backup_marker" ]]; then
        log_info "No backup marker found for $domain - possibly a new zone creation"
        exit 0
    fi

    local backup_file
    backup_file=$(cat "$backup_marker")

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 0
    fi

    # Get current zone file
    local current_file="${ZONE_DIR}/${domain}.db"

    if [[ ! -f "$current_file" ]]; then
        log_error "Current zone file not found: $current_file"
        exit 0
    fi

    # Get recipient email
    local recipient_email
    recipient_email=$(get_recipient_email "$domain")

    if [[ -z "$recipient_email" ]]; then
        log_error "Could not determine recipient email for domain: $domain"
        exit 0
    fi

    log_info "Sending DNS change notification for $domain to $recipient_email"

    # Send notification
    send_dns_change_notification "$domain" "$backup_file" "$current_file" "$recipient_email"

    # Clean up backup marker
    rm -f "$backup_marker"

    log_info "DNS notification completed for domain: $domain"
    exit 0
}

# Execute main function
main "$@"
