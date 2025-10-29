#!/bin/bash
# SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
# ITCMS.GR Free License – All Rights Reserved
# Copyright (c) 2025 Antonios Voulvoulis
#
################################################################################
# DirectAdmin Account & Domain Report
#
# Description:
# DirectAdmin Account & Domain Report
# Outputs CSV: account,space_kb,domain,domain_php_version,hostname
# Author: Antonios Voulvoulis
# Contact: contact@itcms.gr
# Website: https://itcms.gr
#
################################################################################

set -euo pipefail

DA_ADMIN_CLI="${DA_ADMIN_CLI:-/usr/local/directadmin/directadmin}"
HOSTNAME="$(hostname -f || hostname || echo 'unknown-host')"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="${OUTPUT_FILE:-da_report_${TIMESTAMP}.csv}"

err() { printf 'ERROR: %s\n' "$*" >&2; }

csv_escape() {
    local s="$*"
    # Enclose the full regex pattern in double quotes to prevent shell splitting.
    # Note: Using regex OR (|) instead of Bash OR (||) for the pattern.
    if [[ "$s" =~ [,\"]|^[[:space:]]|[[:space:]]$ ]]; then
        s="${s//\"/\"\"}"
        printf '"%s"' "$s"
    else
        printf '%s' "$s"
    fi
}

require_cli() {
    [[ -x "$DA_ADMIN_CLI" ]] || { err "DirectAdmin CLI not executable: $DA_ADMIN_CLI"; exit 10; };
}

get_php_version() {
    local USERNAME="$1" DOMAIN="$2"
    local php_key
    if ! php_key="$("$DA_ADMIN_CLI" cmd=show_user_config user="$USERNAME" 2>/dev/null | awk -F'=' '/^php[0-9]+/{print $1; exit}')"; then
        php_key=""
    fi
    [[ -n "$php_key" ]] && printf '%s\n' "$php_key" || printf 'Unknown/User Default\n'
}

main() {
    require_cli
    printf 'account,space_kb,domain,domain_php_version,hostname\n' >"$OUTPUT_FILE"

    local ACCOUNTS
    ACCOUNTS="$("$DA_ADMIN_CLI" cmd=show_users 2>/dev/null)" || { err "Failed to get users"; exit 20; }

    local ACCOUNT
    while IFS= read -r ACCOUNT; do
        [[ -z "$ACCOUNT" ]] && continue

        local SPACE_KB
        SPACE_KB="$("$DA_ADMIN_CLI" cmd=show_user_config user="$ACCOUNT" 2>/dev/null | awk -F'=' '/^quota=/{print $2; exit}')"
        SPACE_KB="${SPACE_KB:-0}"

        local DOMAINS
        DOMAINS="$("$DA_ADMIN_CLI" cmd=show_user_domains user="$ACCOUNT" 2>/dev/null || true)"

        if [[ -z "$DOMAINS" ]]; then
            printf '%s,%s,%s,%s,%s\n' \
                "$(csv_escape "$ACCOUNT")" \
                "$(csv_escape "$SPACE_KB")" \
                "NO_DOMAIN" \
                "N/A" \
                "$(csv_escape "$HOSTNAME")" >>"$OUTPUT_FILE"
            continue
        fi

        local DOMAIN
        while IFS= read -r DOMAIN; do
            [[ -z "$DOMAIN" ]] && continue
            local DOMAIN_PHP
            DOMAIN_PHP="$(get_php_version "$ACCOUNT" "$DOMAIN")"
            printf '%s,%s,%s,%s,%s\n' \
                "$(csv_escape "$ACCOUNT")" \
                "$(csv_escape "$SPACE_KB")" \
                "$(csv_escape "$DOMAIN")" \
                "$(csv_escape "$DOMAIN_PHP")" \
                "$(csv_escape "$HOSTNAME")" >>"$OUTPUT_FILE"
        done <<< "$DOMAINS"
    done <<< "$ACCOUNTS"

    echo ""
    echo "✅ Report generation complete."
    echo "Output saved to: $OUTPUT_FILE"
}

main "$@"
