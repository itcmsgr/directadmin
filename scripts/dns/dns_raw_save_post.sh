#!/bin/bash
# SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
# ITCMS.GR Free License – All Rights Reserved
# Copyright (c) 2025 Antonios Voulvoulis
#
################################################################################
# dns_raw_save_post.sh - DirectAdmin DNS Raw Save Post-Hook (Multi-Server)
#
# Description:
#   This post-hook is specifically for DirectAdmin Multi-Server DNS (clustered)
#   configurations. It handles DNS zone changes that are pushed from the primary
#   server to secondary servers using raw zone transfers.
#
# DirectAdmin Hook Location:
#   /usr/local/directadmin/scripts/custom/dns_raw_save_post.sh
#
# Environment Variables (provided by DirectAdmin):
#   $domain     - The domain that was modified
#   $username   - The DA username
#   $zonefile   - Path to the zone file
#
# Use Case:
#   When DirectAdmin Multi-Server DNS is configured, zone changes may bypass
#   the normal dns_write_post.sh hook. This script ensures notifications are
#   sent even for raw zone transfers in clustered environments.
#
# NIS2 Compliance:
#   Ensures audit trail completeness in distributed DNS infrastructure,
#   supporting NIS2 Directive (EU) 2022/2555 requirements.
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
DA_DATA_DIR="${DA_DATA_DIR:-/usr/local/directadmin/data}"
DOMAIN_OWNERS="${DOMAIN_OWNERS:-/etc/virtual/domainowners}"
LOG_FILE="${DNS_HOOK_LOG:-/var/log/da-hooks/dns_notify.log}"
SEND_EMAIL="${DNS_SEND_EMAIL:-true}"
EMAIL_FROM="${DNS_EMAIL_FROM:-noreply@$(hostname -f)}"
EMAIL_SUBJECT_PREFIX="${DNS_EMAIL_SUBJECT_PREFIX:-[DNS ALERT - Clustered]}"

# Server identification
SERVER_ROLE="${DA_SERVER_ROLE:-secondary}"  # primary or secondary
CLUSTER_NAME="${DA_CLUSTER_NAME:-default}"

# Ensure directories exist
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# Logging functions
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CLUSTER:$CLUSTER_NAME] $*" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CLUSTER:$CLUSTER_NAME] ERROR: $*" >> "$LOG_FILE" >&2
}

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CLUSTER:$CLUSTER_NAME] INFO: $*" >> "$LOG_FILE"
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
    local da_conf="/usr/local/directadmin/conf/directadmin.conf"
    if [[ -f "$da_conf" ]]; then
        grep -oP '(?<=^admin_email=).*' "$da_conf" | tr -d ' \r\n' || echo "root@$(hostname -f)"
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

# Create zone snapshot
create_zone_snapshot() {
    local domain="$1"
    local zone_file="$2"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_file="${BACKUP_DIR}/${domain}.cluster.${timestamp}.db"

    if cp "$zone_file" "$snapshot_file"; then
        log_info "Created cluster zone snapshot: $snapshot_file"
        echo "$snapshot_file"
    else
        log_error "Failed to create cluster zone snapshot for $domain"
        echo ""
    fi
}

# Send cluster notification
send_cluster_notification() {
    local domain="$1"
    local zone_file="$2"
    local recipient_email="$3"
    local modified_by="${username:-cluster-sync}"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S %Z')

    # Get zone statistics
    local record_count
    record_count=$(grep -cE '^\S+\s+([0-9]+\s+)?IN\s+' "$zone_file" 2>/dev/null || echo "unknown")

    # Build email body
    local email_body
    email_body=$(cat <<EOF
DNS Zone Update Notification (Multi-Server Cluster)
===================================================

DOMAIN:       $domain
SERVER:       $(hostname -f) ($SERVER_ROLE server)
CLUSTER:      $CLUSTER_NAME
MODIFIED BY:  $modified_by
TIMESTAMP:    $timestamp
RECORD COUNT: $record_count

CLUSTER SYNC NOTICE:
This DNS zone was synchronized to this server as part of DirectAdmin
Multi-Server DNS cluster operations. This notification confirms that
the zone has been received and is now active on this server.

SECURITY NOTICE:
If you did not authorize changes to this domain, or if this notification
is unexpected, please contact your hosting administrator immediately.
Unauthorized DNS changes may indicate a security incident.

NIS2 COMPLIANCE:
This notification is part of your DNS infrastructure's audit trail,
supporting governance requirements under EU NIS2 Directive 2022/2555.

--------------------------------------------------------------------------------
ZONE FILE INFORMATION
--------------------------------------------------------------------------------

Zone file path: $zone_file
Zone file size: $(stat -f%z "$zone_file" 2>/dev/null || stat -c%s "$zone_file" 2>/dev/null || echo "unknown") bytes
Last modified:  $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$zone_file" 2>/dev/null || stat -c%y "$zone_file" 2>/dev/null || echo "unknown")

To review the complete zone file, contact your hosting administrator
or access the DirectAdmin control panel.

--------------------------------------------------------------------------------

NEXT STEPS:
1. Verify that DNS propagation is working correctly
2. Test name resolution for this domain
3. Review DNS records if you have access to control panel
4. Report any suspicious changes immediately

For questions or concerns, contact your hosting provider.

---
Generated by DirectAdmin DNS Cluster Monitor
ITCMS DNS Alert System - https://itcms.gr
Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
EOF
)

    # Send email
    local email_subject="${EMAIL_SUBJECT_PREFIX} DNS Zone Update for ${domain}"

    if command -v mail &> /dev/null; then
        echo "$email_body" | mail -s "$email_subject" -r "$EMAIL_FROM" "$recipient_email"
        log_message "Cluster notification sent via 'mail' to $recipient_email for domain $domain"
    elif command -v sendmail &> /dev/null; then
        {
            echo "From: DNS Alert System <${EMAIL_FROM}>"
            echo "To: ${recipient_email}"
            echo "Subject: ${email_subject}"
            echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            echo "$email_body"
        } | sendmail -t -f "$EMAIL_FROM"
        log_message "Cluster notification sent via 'sendmail' to $recipient_email for domain $domain"
    else
        log_error "No mail command available (tried 'mail' and 'sendmail')"
        # Save notification to file as fallback
        local fallback_file="/var/local/da_dns_backups/notifications/cluster_${domain}_${timestamp//[: ]/_}.txt"
        mkdir -p "$(dirname "$fallback_file")"
        echo "$email_body" > "$fallback_file"
        log_message "Cluster notification saved to file: $fallback_file (no mailer available)"
    fi
}

# Main logic
main() {
    # Validate domain variable
    if [[ -z "${domain:-}" ]]; then
        log_error "No domain specified in dns_raw_save_post hook"
        exit 0
    fi

    log_info "DNS raw save post-hook triggered for domain: $domain (server: $SERVER_ROLE)"

    # Check if email sending is enabled
    if [[ "$SEND_EMAIL" != "true" ]]; then
        log_info "Email notifications disabled (DNS_SEND_EMAIL=$SEND_EMAIL)"
        exit 0
    fi

    # Determine zone file path
    local zone_file="${zonefile:-${ZONE_DIR}/${domain}.db}"

    if [[ ! -f "$zone_file" ]]; then
        log_error "Zone file not found: $zone_file"
        exit 0
    fi

    # Create snapshot
    local snapshot
    snapshot=$(create_zone_snapshot "$domain" "$zone_file")

    # Get recipient email
    local recipient_email
    recipient_email=$(get_recipient_email "$domain")

    if [[ -z "$recipient_email" ]]; then
        log_error "Could not determine recipient email for domain: $domain"
        exit 0
    fi

    log_info "Sending cluster DNS notification for $domain to $recipient_email"

    # Send notification
    send_cluster_notification "$domain" "$zone_file" "$recipient_email"

    log_info "Cluster DNS notification completed for domain: $domain"
    exit 0
}

# Execute main function
main "$@"
