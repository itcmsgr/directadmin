#!/usr/bin/env bash
# Runs before all DirectAdmin commands
# If the command is DNS save, copy the current zone file as a backup for diffing later.

set -euo pipefail

# Expect env vars from DA, e.g. $command, $action, $domain
COMMAND="${command:-}"
ACTION="${action:-}"
DOMAIN="${domain:-}"

BACKUP_DIR="/root/tmp_dns_backup"
ZONE_DIR="/var/named"            # adjust for Debian-based: /etc/bind

if [[ "$COMMAND" == "/CMD_DNS_ADMIN" && "$ACTION" == "save" && -n "$DOMAIN" ]]; then
  mkdir -p "$BACKUP_DIR"
  OLD_ZONE="$ZONE_DIR/${DOMAIN}.db"
  if [[ -f "$OLD_ZONE" ]]; then
    cp -f "$OLD_ZONE" "$BACKUP_DIR/${DOMAIN}.db.old"
    echo "Saved old zone: $BACKUP_DIR/${DOMAIN}.db.old"
  fi
fi

exit 0
