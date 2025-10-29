# Security Policy

## Reporting Security Vulnerabilities

The security of this DNS monitoring system is important. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Email**: security@itcms.gr

**Include**:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

**Response Time**:
- Initial response: Within 48 hours
- Status update: Within 7 days
- Fix timeline: Varies by severity

### What to Expect

1. **Acknowledgment**: We'll confirm receipt of your report
2. **Investigation**: We'll investigate and assess the impact
3. **Fix Development**: We'll develop and test a fix
4. **Disclosure**: We'll coordinate disclosure timing with you
5. **Credit**: You'll be credited in the security advisory (if desired)

### Please Do NOT

- ❌ Publicly disclose the vulnerability before we've addressed it
- ❌ Exploit the vulnerability beyond proof-of-concept
- ❌ Access or modify data belonging to others
- ❌ Perform DoS attacks or destructive testing

---

## Supported Versions

Currently supported versions for security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

---

## Security Considerations

### DNS Monitoring System

#### Potential Security Risks

1. **Email Security**
   - Notifications sent via unencrypted email
   - DNS records may contain sensitive information
   - **Mitigation**: For sensitive environments, modify scripts to use encryption

2. **Backup Storage**
   - Backups contain full DNS zones
   - May include internal infrastructure details
   - **Mitigation**: Restrict access to backup directory

3. **Log Files**
   - Logs contain usernames, domains, and IP addresses
   - Could reveal infrastructure details
   - **Mitigation**: Secure log directory, implement log rotation

4. **Hook Script Permissions**
   - Scripts run with DirectAdmin privileges
   - Improper permissions could allow escalation
   - **Mitigation**: Ensure hooks are owned by root with mode 755

5. **Command Injection**
   - Domain names used in shell commands
   - Malicious domain names could inject commands
   - **Mitigation**: Scripts use proper quoting and parameter expansion

### Security Best Practices

#### 1. File Permissions

```bash
# Hook scripts
sudo chown root:root /usr/local/directadmin/scripts/custom/*.sh
sudo chmod 755 /usr/local/directadmin/scripts/custom/*.sh

# Backup directory (restrict access)
sudo chown root:root /var/local/da_dns_backups
sudo chmod 700 /var/local/da_dns_backups

# Log directory
sudo chown root:adm /var/log/da-hooks
sudo chmod 750 /var/log/da-hooks
sudo chmod 640 /var/log/da-hooks/*.log
```

#### 2. Log Rotation

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/da-hooks <<EOF
/var/log/da-hooks/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        # Optional: notify on rotation
        /usr/bin/logger "DA DNS hooks logs rotated"
    endscript
}
EOF
```

#### 3. Backup Cleanup

```bash
# Automatic cleanup of old backups
# Add to /etc/cron.daily/da-dns-cleanup

#!/bin/bash
# Clean backups older than 90 days
find /var/local/da_dns_backups -type f -name "*.db" -mtime +90 -delete

# Clean notification files older than 30 days
find /var/local/da_dns_backups/notifications -type f -mtime +30 -delete
```

#### 4. Email Encryption (Optional)

For sensitive environments, encrypt email notifications:

```bash
# Install GPG
sudo yum install gnupg  # RHEL/CentOS
sudo apt-get install gnupg  # Debian/Ubuntu

# Import recipient's public key
gpg --import recipient-pubkey.asc

# Modify dns_write_post.sh to encrypt email body:
echo "$email_body" | gpg --encrypt --armor --recipient user@example.com | \
    mail -s "$email_subject" "$recipient_email"
```

#### 5. Audit Trail Protection

Forward logs to immutable storage:

```bash
# Send logs to remote syslog
echo "*.* @@siem.example.com:514" | sudo tee -a /etc/rsyslog.conf
sudo systemctl restart rsyslog

# Or use auditd
sudo auditctl -w /var/log/da-hooks -p wa -k dns_logs
```

---

## Known Security Limitations

### 1. Email Transport Security

**Issue**: Notifications sent via standard email (SMTP)

**Risk**: Email could be intercepted in transit

**Mitigations**:
- Use SPF/DKIM/DMARC for email authentication
- Consider GPG encryption for sensitive environments
- Use webhook notifications instead of email for internal monitoring

### 2. Backup Storage Security

**Issue**: Backups stored on local filesystem

**Risk**: System compromise could expose DNS data

**Mitigations**:
- Restrict directory permissions (mode 700)
- Encrypt backup storage volume
- Implement automatic backup cleanup
- Consider off-system backup storage

### 3. Log Tampering

**Issue**: Local logs can be modified by root

**Risk**: Attacker with root access could delete audit trail

**Mitigations**:
- Forward logs to remote syslog/SIEM
- Use write-once storage for critical logs
- Implement file integrity monitoring (AIDE, Tripwire)

### 4. DirectAdmin Privilege

**Issue**: Hooks run with DirectAdmin's privileges

**Risk**: Vulnerability in hooks could affect DA

**Mitigations**:
- Keep hooks simple and well-audited
- Use safe shell scripting practices
- Run periodic security reviews

---

## Security Checklist

Use this checklist to secure your installation:

- [ ] Hook scripts owned by root with mode 755
- [ ] Backup directory mode 700 (restricted access)
- [ ] Log directory secured with appropriate permissions
- [ ] Log rotation configured
- [ ] Backup cleanup scheduled
- [ ] Email authentication (SPF/DKIM) configured
- [ ] Consider email encryption for sensitive data
- [ ] Remote log forwarding enabled (optional)
- [ ] File integrity monitoring configured (optional)
- [ ] Regular security audits scheduled
- [ ] Incident response procedures documented
- [ ] Access to backups limited to authorized users
- [ ] DirectAdmin itself is kept up-to-date
- [ ] Server firewall configured properly

---

## Compliance Considerations

### NIS2 Directive

For organizations subject to NIS2:

**Security Requirements**:
- Implement appropriate security measures
- Protect audit logs from tampering
- Encrypt sensitive data
- Control access to DNS infrastructure
- Monitor for security incidents

**This System's Role**:
- Supports incident detection
- Provides audit trail
- Does NOT replace comprehensive security controls

### Data Protection

**Personal Data Handling**:
- Email addresses stored in logs and notifications
- Usernames logged for attribution
- Domain ownership information processed

**GDPR Compliance** (if applicable):
- Document data processing in privacy policy
- Implement appropriate retention periods
- Secure personal data adequately
- Provide data access/deletion upon request

---

## Secure Configuration Examples

### Minimal Exposure Configuration

```bash
# Disable notifications entirely, only log changes
export DNS_SEND_EMAIL="false"

# Use restrictive permissions
sudo chmod 700 /var/local/da_dns_backups
sudo chmod 750 /var/log/da-hooks
sudo chmod 640 /var/log/da-hooks/*.log

# Short retention
export DNS_BACKUP_RETENTION="3"

# Forward logs immediately
logger -t directadmin-dns "$(cat /var/log/da-hooks/dns_notify.log)"
```

### High-Security Configuration

```bash
# Enable email but with encryption
export DNS_SEND_EMAIL="true"
export DNS_EMAIL_GPG_ENCRYPT="true"
export DNS_EMAIL_GPG_KEY_ID="user@example.com"

# Longer retention for audit
export DNS_BACKUP_RETENTION="365"

# Restricted access
sudo chmod 700 /var/local/da_dns_backups
sudo chown root:root /var/local/da_dns_backups

# Remote logging
echo "*.* @@siem.example.com:514" >> /etc/rsyslog.conf

# File integrity monitoring
sudo aide --init
sudo aide --check
```

---

## Security Updates

Security updates will be announced:

1. **Email**: Sent to users who requested notifications
2. **GitHub**: Security advisory published
3. **Website**: Posted on https://itcms.gr

### Subscribing to Security Announcements

Email security@itcms.gr with subject "Subscribe to Security Announcements"

---

## Past Security Issues

None reported as of 2025-10-29.

---

## Security Resources

### General Security

- OWASP Top Ten: https://owasp.org/www-project-top-ten/
- CIS Controls: https://www.cisecurity.org/controls
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework

### Shell Script Security

- ShellCheck: https://www.shellcheck.net/
- Bash Security Guide: https://mywiki.wooledge.org/BashGuide/Practices

### Linux Security

- Linux Security Modules: https://www.kernel.org/doc/html/latest/admin-guide/LSM/index.html
- SELinux: https://selinuxproject.org/
- AppArmor: https://apparmor.net/

---

## Contact

**Security Issues**: security@itcms.gr
**General Support**: contact@itcms.gr
**Website**: https://itcms.gr

**PGP Key**: Available at https://itcms.gr/pgp (coming soon)

---

## Acknowledgments

We thank the following individuals for responsibly reporting security issues:

- (None yet - be the first!)

---

**Copyright © 2025 Antonios Voulvoulis, ITCMS.GR**
**SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0**
