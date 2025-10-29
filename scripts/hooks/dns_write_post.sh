#!/usr/bin/env bash
# After DA writes a DNS zone, email the owner a diff of old vs new.

set -euo pipefail

DOMAIN="${domain:-}"
ZONE_DIR="/var/named"             # adjust for Debian-based: /etc/bind
BACKUP_DIR="/root/tmp_dns_backup"
LOG_DIR="/var/log/da-hooks"
LOG_FILE="$LOG_DIR/dns_notify.log"

mkdir -p "$LOG_DIR"

if [[ -z "$DOMAIN" ]]; then
  echo "[$(date -Is)] missing $domain env" >>"$LOG_FILE"
  exit 0
fi

OLD_FILE="$BACKUP_DIR/${DOMAIN}.db.old"
NEW_FILE="$ZONE_DIR/${DOMAIN}.db"

if [[ ! -f "$NEW_FILE" || ! -f "$OLD_FILE" ]]; then
  echo "[$(date -Is)] skip: missing files for $DOMAIN (old=$OLD_FILE new=$NEW_FILE)" >>"$LOG_FILE"
  exit 0
fi

DNS_DIFF=$(diff -u "$OLD_FILE" "$NEW_FILE" || true)

if [[ -z "$DNS_DIFF" ]]; then
  echo "[$(date -Is)] no changes for $DOMAIN" >>"$LOG_FILE"
  rm -f "$OLD_FILE"
  exit 0
fi

# Resolve owner email
get_username() {
  awk -v d="$DOMAIN" '$1==d {print $2; exit}' /etc/virtual/domainowners 2>/dev/null || true
}

get_user_email() {
  local U="$1"; [[ -z "$U" ]] && return 0
  awk -F'=' '/^email=/{print $2; exit}' \
    "/usr/local/directadmin/data/users/${U}/user.conf" 2>/dev/null || true
}

get_admin_email() {
  awk -F'=' '/^admin_email=/{print $2; exit}' /usr/local/directadmin/conf/directadmin.conf 2>/dev/null || echo "root@localhost"
}

USERNAME="$(get_username)"
OWNER_EMAIL="$(get_user_email "$USERNAME")"
ADMIN_EMAIL="$(get_admin_email)"
TO_EMAIL="${OWNER_EMAIL:-$ADMIN_EMAIL}"

SUBJECT="[DirectAdmin] DNS records changed for ${DOMAIN}"
BODY=$(cat <<EOF
This is an automated notification. The DNS zone for ${DOMAIN} was modified.

- Owner: ${USERNAME:-unknown}
- When : $(date -Is)
- Host : $(hostname -f || hostname)

Legend:
- lines starting with '-' are PREVIOUS values
- lines starting with '+' are CURRENT values

--------------------------------------------------
$DNS_DIFF
--------------------------------------------------

If you did not authorize this change, please contact your hosting provider immediately.
EOF
)

send_mail() {
  if command -v mail >/dev/null 2>&1; then
    printf '%s\n' "$BODY" | mail -s "$SUBJECT" "$TO_EMAIL"
  elif command -v sendmail >/dev/null 2>&1; then
    {
      echo "To: $TO_EMAIL";
      echo "Subject: $SUBJECT";
      echo "MIME-Version: 1.0";
      echo "Content-Type: text/plain; charset=UTF-8";
      echo;
      printf '%s\n' "$BODY";
    } | sendmail -t
  else
    echo "[$(date -Is)] ERROR: no mailer on system for $DOMAIN" >>"$LOG_FILE"
    return 1
  fi
}

if send_mail; then
  echo "[$(date -Is)] mailed diff to $TO_EMAIL for $DOMAIN" >>"$LOG_FILE"
else
  echo "[$(date -Is)] failed to mail diff for $DOMAIN" >>"$LOG_FILE"
fi

# cleanup old backup
rm -f "$OLD_FILE"

exit 0
