# DNS Change Notifications

> Real-time email alerts for DNS zone modifications in DirectAdmin

---

## Overview

The DNS Change Notification system uses DirectAdmin custom hooks to detect DNS zone modifications and automatically email domain owners with detailed before/after comparisons. This provides immediate visibility into DNS changes for security and compliance purposes.

---

## How It Works

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Admin edits DNS via DirectAdmin Control Panel               │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  all_pre.sh (Pre-Hook)                                       │
│  • Triggered before DNS save                                 │
│  • Detects CMD_DNS_ADMIN / CMD_DNS_CONTROL                  │
│  • Backs up current zone file to timestamped location        │
│  • Creates marker file with backup path                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  DirectAdmin writes new zone file                            │
│  /var/named/domain.db (updated)                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  dns_write_post.sh (Post-Hook)                               │
│  • Triggered after DNS save                                  │
│  • Reads backup marker to find old zone                      │
│  • Generates unified diff (old vs new)                       │
│  • Filters out SOA-only changes (serial updates)             │
│  • Determines domain owner via /etc/virtual/domainowners     │
│  • Reads owner email from user.conf                          │
│  • Sends email notification with diff                        │
│  • Logs action for audit trail                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Domain owner receives email:                                │
│  Subject: [DNS ALERT] DNS Changes for domain.com             │
│  Body: Unified diff + security notice + compliance info      │
└─────────────────────────────────────────────────────────────┘
```

---

## Installation

### Prerequisites

- DirectAdmin installed (version 1.60+)
- Root or admin access
- Mail system configured (`mail` or `sendmail` command)
- Bash 4.0+

### Step 1: Install Hook Scripts

```bash
# Create custom hooks directory
sudo mkdir -p /usr/local/directadmin/scripts/custom

# Copy hook scripts
sudo cp scripts/dns/all_pre.sh \
        scripts/dns/dns_write_post.sh \
        /usr/local/directadmin/scripts/custom/

# Set executable permissions
sudo chmod 755 /usr/local/directadmin/scripts/custom/all_pre.sh
sudo chmod 755 /usr/local/directadmin/scripts/custom/dns_write_post.sh
```

### Step 2: Create Required Directories

```bash
# Backup storage
sudo mkdir -p /var/local/da_dns_backups
sudo chmod 755 /var/local/da_dns_backups

# Log directory
sudo mkdir -p /var/log/da-hooks
sudo chmod 755 /var/log/da-hooks
```

### Step 3: Verify Mail System

```bash
# Test mail command
echo "Test email from DirectAdmin DNS Alert System" | \
    mail -s "Test Subject" your-email@example.com

# If mail is not available, install it:
# RHEL/CentOS/Rocky:
sudo yum install mailx

# Debian/Ubuntu:
sudo apt-get install mailutils
```

### Step 4: Test Installation

```bash
# Manually trigger pre-hook
sudo domain=test.com \
    command=CMD_DNS_ADMIN \
    action=save \
    /usr/local/directadmin/scripts/custom/all_pre.sh

# Check logs
sudo cat /var/log/da-hooks/dns_backup.log

# Verify backup was created
sudo ls -lh /var/local/da_dns_backups/
```

---

## Configuration

### Environment Variables

Configure the hooks using environment variables in `/etc/default/da-dns-alerts`:

```bash
# Create configuration file
sudo tee /etc/default/da-dns-alerts <<'EOF'
# Zone file directory
ZONE_DIR="/var/named"                           # or /etc/bind for Debian

# Backup storage
DNS_BACKUP_DIR="/var/local/da_dns_backups"

# Log file
DNS_HOOK_LOG="/var/log/da-hooks/dns_notify.log"

# Enable/disable email notifications
DNS_SEND_EMAIL="true"

# Email from address
DNS_EMAIL_FROM="dns-alert@example.com"

# Email subject prefix
DNS_EMAIL_SUBJECT_PREFIX="[DNS ALERT]"

# Maximum diff lines in email (truncate if exceeded)
DNS_MAX_DIFF_LINES="500"

# Backup retention in days
DNS_BACKUP_RETENTION="7"

# DirectAdmin paths
DA_CONF="/usr/local/directadmin/conf/directadmin.conf"
DA_DATA_DIR="/usr/local/directadmin/data"
DOMAIN_OWNERS="/etc/virtual/domainowners"
EOF

# Set permissions
sudo chmod 644 /etc/default/da-dns-alerts
```

### Hook Script Modification

To use custom configuration, edit the hook scripts:

```bash
# Edit all_pre.sh
sudo nano /usr/local/directadmin/scripts/custom/all_pre.sh

# Add configuration sourcing at the top (after shebang):
if [ -f /etc/default/da-dns-alerts ]; then
    . /etc/default/da-dns-alerts
fi

# Repeat for dns_write_post.sh
```

---

## Email Notification Format

### Subject Line

```
[DNS ALERT] DNS Changes for example.com
```

### Email Body

```
DNS Zone Change Notification
============================

DOMAIN:      example.com
MODIFIED BY: admin
TIMESTAMP:   2025-10-29 14:32:15 UTC
SERVER:      server.example.com

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

--- /var/local/da_dns_backups/example.com.20251029_143000.db   2025-10-29 14:30:00
+++ /var/named/example.com.db                                   2025-10-29 14:32:15
@@ -8,12 +8,12 @@
 $TTL 14400
 @       IN      SOA     ns1.example.com. hostmaster.example.com. (
-                        2025102901      ; serial
+                        2025102902      ; serial
                         14400           ; refresh
                         3600            ; retry
                         1209600         ; expire
                         86400 )         ; minimum

 @               IN      NS      ns1.example.com.
 @               IN      NS      ns2.example.com.
-www             IN      A       192.0.2.1
+www             IN      A       192.0.2.100
 ftp             IN      A       192.0.2.2
+mail            IN      A       192.0.2.50
 @               IN      MX      10 mail.example.com.

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
```

### Understanding the Diff Format

The unified diff format shows changes using these symbols:

| Symbol | Meaning | Example |
|--------|---------|---------|
| `-` | Removed line (OLD value) | `-www IN A 192.0.2.1` |
| `+` | Added line (NEW value) | `+www IN A 192.0.2.100` |
| `@@ -8,12 +8,12 @@` | Line numbers (old file lines 8-12, new file lines 8-12) | Context for changes |
| (space) | Unchanged line (context) | ` ftp IN A 192.0.2.2` |

---

## How Email Recipients Are Determined

### Domain Owner Resolution Process

1. **Map domain to username**:
   ```bash
   grep "^example.com:" /etc/virtual/domainowners
   # Output: example.com: user1
   ```

2. **Get user's email**:
   ```bash
   grep "^email=" /usr/local/directadmin/data/users/user1/user.conf
   # Output: email=user@example.com
   ```

3. **Fallback to admin email** (if owner email not found):
   ```bash
   grep "^admin_email=" /usr/local/directadmin/conf/directadmin.conf
   # Output: admin_email=admin@server.com
   ```

### Testing Email Resolution

```bash
# Test domain ownership lookup
DOMAIN="example.com"
OWNER=$(grep "^${DOMAIN}:" /etc/virtual/domainowners | cut -d: -f2)
echo "Domain: $DOMAIN, Owner: $OWNER"

# Test email lookup
EMAIL=$(grep "^email=" /usr/local/directadmin/data/users/$OWNER/user.conf | cut -d= -f2)
echo "Owner Email: $EMAIL"
```

---

## Multi-Server DNS (Clustered Environments)

For DirectAdmin Multi-Server DNS configurations, use the additional `dns_raw_save_post.sh` hook:

### Installation

```bash
# Install cluster hook
sudo cp scripts/dns/dns_raw_save_post.sh \
    /usr/local/directadmin/scripts/custom/
sudo chmod 755 /usr/local/directadmin/scripts/custom/dns_raw_save_post.sh
```

### Configuration

```bash
# Add cluster configuration to /etc/default/da-dns-alerts
echo 'DA_SERVER_ROLE="secondary"' | sudo tee -a /etc/default/da-dns-alerts
echo 'DA_CLUSTER_NAME="production-cluster"' | sudo tee -a /etc/default/da-dns-alerts
```

### When to Use

Use `dns_raw_save_post.sh` when:
- You have DirectAdmin Multi-Server DNS enabled
- DNS zones are synchronized from primary to secondary servers
- You want notifications on secondary/slave nameservers

---

## Troubleshooting

### No Emails Being Sent

**Symptoms**: DNS changes occur but no emails received

**Diagnosis**:

```bash
# 1. Check if hook is being triggered
sudo tail -f /var/log/da-hooks/dns_notify.log

# Expected output when DNS is modified:
# [2025-10-29 14:32:15] INFO: DNS write post-hook triggered for domain: example.com
# [2025-10-29 14:32:15] INFO: Sending DNS change notification for example.com to user@example.com
# [2025-10-29 14:32:16] Notification sent via 'mail' to user@example.com for domain example.com

# 2. Check for errors
sudo grep ERROR /var/log/da-hooks/dns_notify.log

# 3. Verify mail system
echo "Test" | mail -s "Test" your@email.com

# 4. Check if emails are disabled
grep DNS_SEND_EMAIL /etc/default/da-dns-alerts
```

**Solutions**:

```bash
# Solution 1: Enable email notifications
echo 'DNS_SEND_EMAIL="true"' | sudo tee -a /etc/default/da-dns-alerts

# Solution 2: Install mail command
# RHEL/CentOS:
sudo yum install mailx

# Debian/Ubuntu:
sudo apt-get install mailutils

# Solution 3: Check backup marker
sudo ls -la /var/local/da_dns_backups/*.last_backup

# Solution 4: Manually test post-hook
sudo domain=example.com username=admin \
    DNS_SEND_EMAIL=true \
    /usr/local/directadmin/scripts/custom/dns_write_post.sh
```

### Hooks Not Executing

**Symptoms**: No log entries when DNS is modified

**Diagnosis**:

```bash
# 1. Verify hooks are installed
ls -lh /usr/local/directadmin/scripts/custom/

# Expected output:
# -rwxr-xr-x 1 root root 4.2K all_pre.sh
# -rwxr-xr-x 1 root root 8.1K dns_write_post.sh

# 2. Check permissions
stat /usr/local/directadmin/scripts/custom/all_pre.sh
# Should show: Access: (0755/-rwxr-xr-x)

# 3. Test for syntax errors
sudo bash -n /usr/local/directadmin/scripts/custom/all_pre.sh
sudo bash -n /usr/local/directadmin/scripts/custom/dns_write_post.sh
```

**Solutions**:

```bash
# Solution 1: Fix permissions
sudo chmod 755 /usr/local/directadmin/scripts/custom/*.sh

# Solution 2: Verify DirectAdmin hook system
# Check DirectAdmin logs
sudo tail -f /var/log/directadmin/error.log

# Solution 3: Manually trigger hooks
sudo domain=test.com command=CMD_DNS_ADMIN action=save \
    /usr/local/directadmin/scripts/custom/all_pre.sh
```

### Backup Not Created

**Symptoms**: `dns_write_post.sh` logs "No backup marker found"

**Diagnosis**:

```bash
# 1. Check pre-hook logs
sudo cat /var/log/da-hooks/dns_backup.log

# 2. Verify backup directory permissions
ls -ld /var/local/da_dns_backups
# Should show: drwxr-xr-x

# 3. Check zone file path
ls -la /var/named/*.db  # RHEL/CentOS
ls -la /etc/bind/*.db   # Debian/Ubuntu
```

**Solutions**:

```bash
# Solution 1: Create backup directory
sudo mkdir -p /var/local/da_dns_backups
sudo chmod 755 /var/local/da_dns_backups

# Solution 2: Fix zone directory path (Debian/Ubuntu)
sudo sed -i 's|/var/named|/etc/bind|g' \
    /usr/local/directadmin/scripts/custom/all_pre.sh \
    /usr/local/directadmin/scripts/custom/dns_write_post.sh

# Solution 3: Manually test pre-hook
sudo domain=example.com command=CMD_DNS_ADMIN action=save \
    /usr/local/directadmin/scripts/custom/all_pre.sh

# Verify backup created
sudo ls -lh /var/local/da_dns_backups/
```

### Only SOA Serial Changes

**Symptoms**: Email not sent even though zone was modified

**Explanation**: The post-hook filters out changes that only affect SOA serial numbers, as these occur with every save and don't represent meaningful DNS changes.

**Diagnosis**:

```bash
# Check logs for "No meaningful DNS changes" message
sudo grep "No meaningful" /var/log/da-hooks/dns_notify.log
```

**Expected Behavior**: This is intentional. Notifications are suppressed for serial-only changes to avoid spam.

**To Change**: Modify `dns_write_post.sh` and remove/comment out the SOA filtering logic around line 150.

### Email Goes to Wrong Recipient

**Symptoms**: Email sent to admin instead of domain owner

**Diagnosis**:

```bash
# Check domain ownership
DOMAIN="example.com"
grep "^${DOMAIN}:" /etc/virtual/domainowners

# Check user email
OWNER=$(grep "^${DOMAIN}:" /etc/virtual/domainowners | cut -d: -f2)
cat /usr/local/directadmin/data/users/$OWNER/user.conf | grep email
```

**Solutions**:

```bash
# Solution 1: Update domain owner email in DirectAdmin
# Log into DirectAdmin as reseller/admin
# User Level -> Manage User -> Modify User -> Email

# Solution 2: Manually fix user.conf
sudo nano /usr/local/directadmin/data/users/username/user.conf
# Set: email=correct@email.com

# Solution 3: Verify domainowners file
sudo cat /etc/virtual/domainowners | grep example.com
# Should show: example.com: username
```

---

## Advanced Configuration

### Custom Email Templates

Modify `dns_write_post.sh` to customize the email format:

```bash
sudo nano /usr/local/directadmin/scripts/custom/dns_write_post.sh

# Find the email_body section (around line 180)
# Customize the cat <<EOF section
```

### Notification Suppression Rules

Add logic to suppress notifications for specific domains or users:

```bash
# In dns_write_post.sh, after domain validation:

# Suppress notifications for specific domains
if [[ "$domain" == "internal.example.com" ]]; then
    log_info "Notifications suppressed for internal domain: $domain"
    exit 0
fi

# Suppress for specific users
if [[ "$username" == "monitoring" ]]; then
    log_info "Notifications suppressed for user: $username"
    exit 0
fi
```

### Multiple Recipients

Send notifications to multiple email addresses:

```bash
# In dns_write_post.sh, modify the email sending section:

# Add CC recipients
ADDITIONAL_RECIPIENTS="dns-team@example.com,security@example.com"

echo "$email_body" | mail -s "$email_subject" \
    -r "$EMAIL_FROM" \
    -c "$ADDITIONAL_RECIPIENTS" \
    "$recipient_email"
```

### Webhook Integration

Add webhook notifications (Slack, Teams, Discord):

```bash
# In dns_write_post.sh, after email is sent:

# Slack webhook
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
curl -X POST "$SLACK_WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"DNS changed for $domain by $modified_by\"}"

# Microsoft Teams
TEAMS_WEBHOOK="https://your-tenant.webhook.office.com/..."
curl -X POST "$TEAMS_WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"DNS Alert: $domain modified by $modified_by\"}"
```

---

## Security Considerations

### Email Security

- **Unencrypted Email**: Notifications are sent via standard email (plaintext)
- **Sensitive Data**: DNS records may contain internal infrastructure details
- **Recommendation**: For highly sensitive environments, consider:
  - PGP/GPG encryption for emails
  - Webhook notifications to internal systems
  - HTTPS-based notification delivery

### Backup Security

- **Backup Storage**: Contains full DNS zones with all records
- **Access Control**: Restrict access to `/var/local/da_dns_backups/`
- **Retention**: Configure appropriate retention period (default: 7 days)

```bash
# Secure backup directory
sudo chmod 700 /var/local/da_dns_backups
sudo chown root:root /var/local/da_dns_backups

# Set up automatic cleanup
echo "0 3 * * * find /var/local/da_dns_backups -name '*.db' -mtime +7 -delete" | \
    sudo crontab -
```

### Log Security

- **Log Contents**: May contain usernames, domains, IP addresses
- **Access Control**: Restrict log file access

```bash
# Secure log directory
sudo chmod 750 /var/log/da-hooks
sudo chown root:adm /var/log/da-hooks

# Set up log rotation
sudo tee /etc/logrotate.d/da-hooks <<EOF
/var/log/da-hooks/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
}
EOF
```

---

## Monitoring & Alerting

### Monitor Hook Execution

```bash
# Check for recent notifications
sudo tail -20 /var/log/da-hooks/dns_notify.log

# Count notifications per day
sudo grep "Notification sent" /var/log/da-hooks/dns_notify.log | \
    cut -d' ' -f1 | cut -d'[' -f2 | cut -d' ' -f1 | sort | uniq -c

# Monitor for errors
sudo tail -f /var/log/da-hooks/dns_notify.log | grep ERROR
```

### Alert on Hook Failures

```bash
#!/bin/bash
# /etc/cron.hourly/check-dns-hooks

LOG_FILE="/var/log/da-hooks/dns_notify.log"
ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE")

if [ "$ERROR_COUNT" -gt 0 ]; then
    tail -20 "$LOG_FILE" | grep ERROR | \
        mail -s "DNS Hook Errors Detected" admin@example.com
fi
```

---

## NIS2 Compliance

### Audit Trail

The DNS notification system provides:

- **Change Detection**: Real-time notification of DNS modifications
- **Attribution**: Records who made changes (admin username)
- **Timestamping**: Exact time of modification
- **Change Details**: Complete before/after comparison
- **Retention**: Configurable backup retention for audit purposes

### Documentation Requirements

For NIS2 compliance, document:

1. **System Description**: How DNS monitoring works
2. **Notification Procedures**: Who receives alerts and how
3. **Retention Policies**: How long backups and logs are kept
4. **Incident Response**: What to do when unauthorized changes are detected
5. **Testing**: Regular testing procedures

---

## Support

### Documentation

- Main README: [../README.md](../README.md)
- Reporting Guide: [da_report.md](da_report.md)
- NIS2 Compliance: [NIS2.md](NIS2.md)

### Contact

- **Email**: contact@itcms.gr
- **Support**: support@itcms.gr
- **Website**: https://itcms.gr

---

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
Licensed under ITCMS.GR Free License
SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0

---

*Part of the DirectAdmin DNS Change Alert System*
*https://itcms.gr*
