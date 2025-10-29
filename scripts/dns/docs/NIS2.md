# NIS2 Compliance for DNS Infrastructure

> Quick reference: How this DNS monitoring system supports NIS2 compliance

---

## What is NIS2?

**NIS2 Directive (EU) 2022/2555** - EU cybersecurity regulation effective October 2024.

**Applies to**: Essential and important entities including DNS service providers, hosting providers, and digital infrastructure operators.

**Key Requirements**:
- Incident detection and reporting
- Risk management measures
- Security of network and information systems
- Supply chain security
- Business continuity

**For full directive details**: [EUR-Lex Official Text](https://eur-lex.europa.eu/eli/dir/2022/2555)

---

## Why DNS Monitoring Matters for NIS2

### DNS as Critical Infrastructure

DNS is explicitly mentioned in NIS2 as critical infrastructure. Service providers must:

1. **Detect incidents** - Unauthorized DNS changes can indicate:
   - Account compromise
   - DNS hijacking attempts
   - Insider threats
   - Configuration errors leading to service disruption

2. **Maintain audit trails** - Document who changed what and when

3. **Report significant incidents** - Within strict timeframes (24h early warning, 72h incident notification)

4. **Demonstrate governance** - Show proactive monitoring and controls

### The Problem

**DirectAdmin doesn't natively provide**:
- Real-time DNS change notifications
- DNS modification audit trails
- Domain owner alerting
- Change attribution (who made the change)

**This creates compliance gaps** for hosting providers and DNS operators.

---

## How This System Helps

### Immediate Benefits

| NIS2 Requirement | This System's Capability |
|------------------|-------------------------|
| **Incident Detection** | Real-time alerts when DNS records change |
| **Attribution** | Logs show which admin made changes |
| **Audit Trail** | Complete before/after history with timestamps |
| **Stakeholder Notification** | Automatic email to domain owners |
| **Evidence Collection** | Backup zone files for forensic analysis |
| **Risk Management** | Early detection of unauthorized changes |

### What This System Does

1. **Captures all DNS changes** - Every record modification is logged
2. **Notifies domain owners** - Immediate email with detailed diff
3. **Creates audit trail** - Timestamped backups with attribution
4. **Enables investigation** - Full before/after comparison
5. **Supports reporting** - Structured logs and notifications for incident reports

### What This System Doesn't Do

❌ This is **NOT** a complete NIS2 compliance solution
❌ Does **NOT** replace ISMS (Information Security Management System)
❌ Does **NOT** handle incident reporting to authorities
❌ Does **NOT** cover all NIS2 requirements (authentication, encryption, patching, etc.)

**Use this as ONE COMPONENT** of your NIS2 compliance program.

---

## Implementation for Compliance

### 1. Deploy the System

```bash
# Install DNS monitoring hooks
sudo cp scripts/dns/all_pre.sh scripts/dns/dns_write_post.sh \
    /usr/local/directadmin/scripts/custom/
sudo chmod 755 /usr/local/directadmin/scripts/custom/*.sh
```

### 2. Configure Retention

```bash
# Set backup retention (adjust based on your compliance requirements)
echo 'DNS_BACKUP_RETENTION="90"' | sudo tee -a /etc/default/da-dns-alerts

# NIS2 suggests keeping incident-related data for investigation periods
# Common practice: 90 days to 1 year
```

### 3. Document the System

For compliance audits, document:

**System Description**:
- How DNS changes are detected (DirectAdmin hooks)
- Who receives notifications (domain owners + admin)
- Where data is stored (`/var/local/da_dns_backups`, `/var/log/da-hooks`)
- Retention periods (configurable, default 7 days)

**Incident Response**:
- What triggers an alert (any DNS record change)
- Who investigates (admin team)
- How to access historical data (backup files and logs)
- Escalation procedures (when to report to authorities)

### 4. Establish Monitoring

```bash
# Daily check for DNS changes
# /etc/cron.daily/nis2-dns-monitoring

#!/bin/bash
LOG_FILE="/var/log/da-hooks/dns_notify.log"
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

# Count DNS changes
CHANGE_COUNT=$(grep "$YESTERDAY" "$LOG_FILE" | grep -c "Notification sent")

# Alert if unusual volume
if [ "$CHANGE_COUNT" -gt 50 ]; then
    echo "Unusual DNS activity: $CHANGE_COUNT changes on $YESTERDAY" | \
        mail -s "NIS2 Alert: High DNS Activity" security@example.com
fi
```

### 5. Regular Reporting

```bash
# Monthly DNS change report for compliance records
#!/bin/bash
MONTH=$(date +%Y-%m)
OUTPUT="/var/compliance/dns_changes_${MONTH}.txt"

grep "Notification sent" /var/log/da-hooks/dns_notify.log | \
    grep "$MONTH" > "$OUTPUT"

echo "DNS Changes for $MONTH: $(wc -l < $OUTPUT)" | \
    mail -s "Monthly DNS Activity Report" compliance@example.com
```

---

## Incident Detection Scenarios

### Scenario 1: Unauthorized DNS Change

**Event**: Admin account compromised, attacker changes MX records

**System Response**:
1. `all_pre.sh` backs up current zone
2. Attacker modifies DNS via DirectAdmin
3. `dns_write_post.sh` detects change, emails domain owner
4. **Owner sees unauthorized change immediately**
5. Owner contacts hosting provider
6. Provider investigates using logs and backups

**NIS2 Requirement Met**: Incident detected and stakeholders notified in real-time

### Scenario 2: Configuration Error

**Event**: Admin accidentally deletes critical A record

**System Response**:
1. Owner receives notification showing deleted record
2. Owner contacts support
3. Support reviews backup showing old record
4. Record restored quickly
5. Incident documented in logs

**NIS2 Requirement Met**: Rapid detection and recovery, full audit trail

### Scenario 3: DNS Hijacking Attempt

**Event**: Attacker changes nameservers to malicious servers

**System Response**:
1. Immediate notification to domain owner
2. Owner sees unauthorized NS record change
3. Emergency response: owner contacts provider
4. Provider locks account, investigates, restores DNS
5. Backup provides forensic evidence

**NIS2 Requirement Met**: Early detection enables rapid response before propagation

---

## Audit Trail Requirements

### What NIS2 Requires

- **Logging**: Record security-relevant events
- **Attribution**: Who performed the action
- **Timestamps**: When it occurred
- **Integrity**: Logs protected from tampering
- **Retention**: Keep for appropriate period

### What This System Provides

**Log Format** (`/var/log/da-hooks/dns_notify.log`):
```
[2025-10-29 14:32:15] Notification sent via 'mail' to owner@example.com for domain example.com
[2025-10-29 14:32:15] INFO: DNS write post-hook triggered for domain: example.com
[2025-10-29 14:32:15] Backed up DNS zone for example.com (command: CMD_DNS_ADMIN, action: save, user: admin)
```

**Backup Files** (`/var/local/da_dns_backups/`):
```
example.com.20251029_143215.db  - Full zone snapshot with timestamp
example.com.last_backup         - Pointer to most recent backup
```

**Email Notifications**: Sent to domain owners with:
- Domain name
- Modification timestamp
- Admin username who made change
- Complete before/after diff
- Server hostname

### Securing the Audit Trail

```bash
# Protect log files from tampering
sudo chmod 640 /var/log/da-hooks/*.log
sudo chown root:adm /var/log/da-hooks/*.log

# Protect backups
sudo chmod 700 /var/local/da_dns_backups
sudo chown root:root /var/local/da_dns_backups

# Optional: Send logs to remote syslog for immutability
echo "*.* @@siem.example.com:514" | sudo tee -a /etc/rsyslog.conf
sudo systemctl restart rsyslog
```

---

## Incident Reporting

### NIS2 Reporting Timelines

**Early Warning**: Within 24 hours of becoming aware
**Incident Notification**: Within 72 hours
**Final Report**: Within 1 month

### Using This System for Reports

When a significant DNS incident occurs:

1. **Identify the incident**:
   ```bash
   # Find all changes for affected domain
   grep "example.com" /var/log/da-hooks/dns_notify.log
   ```

2. **Gather evidence**:
   ```bash
   # Retrieve backup showing unauthorized change
   ls -lh /var/local/da_dns_backups/example.com.*

   # Get diff showing what changed
   diff -u /var/local/da_dns_backups/example.com.20251029_140000.db \
           /var/named/example.com.db
   ```

3. **Document timeline**:
   - When change occurred (from log timestamps)
   - Who made change (from log attribution)
   - When detected (notification timestamp)
   - What changed (from diff)

4. **Include in incident report**:
   - System logs showing unauthorized access
   - DNS change notifications sent to owner
   - Backup files as evidence
   - Remediation actions taken

---

## Best Practices

### 1. Regular Testing

```bash
# Monthly test: Verify notifications are working
sudo domain=test.example.com username=admin \
    DNS_SEND_EMAIL=true \
    /usr/local/directadmin/scripts/custom/dns_write_post.sh

# Check email received
```

### 2. Integration with SIEM

```bash
# Forward logs to SIEM for correlation
# Example: rsyslog to Splunk/ELK/Graylog
echo '$ModLoad imfile' | sudo tee -a /etc/rsyslog.conf
echo '$InputFileName /var/log/da-hooks/dns_notify.log' | sudo tee -a /etc/rsyslog.conf
echo '$InputFileTag directadmin-dns:' | sudo tee -a /etc/rsyslog.conf
echo '$InputFileStateFile stat-dns-notify' | sudo tee -a /etc/rsyslog.conf
echo '$InputRunFileMonitor' | sudo tee -a /etc/rsyslog.conf
```

### 3. Define "Significant Incident"

Document what constitutes a significant DNS incident requiring NIS2 reporting:

**Examples**:
- Unauthorized changes by external attacker
- DNS hijacking affecting service availability
- Configuration errors causing widespread outage
- Supply chain compromise affecting DNS infrastructure

**Not typically significant**:
- Routine authorized changes
- Planned maintenance
- Minor configuration adjustments

### 4. Staff Training

Train admin team on:
- How the DNS monitoring system works
- How to investigate alerts
- When to escalate to security team
- NIS2 incident reporting procedures

---

## Compliance Checklist

- [ ] DNS monitoring hooks installed and tested
- [ ] Email notifications working for all domains
- [ ] Log retention configured appropriately (90+ days recommended)
- [ ] Backup retention configured (match log retention)
- [ ] System documented in ISMS/security policies
- [ ] Incident response procedures defined
- [ ] Staff trained on DNS incident detection
- [ ] Regular testing scheduled (monthly)
- [ ] Integration with SIEM/monitoring (if applicable)
- [ ] Backup and log protection implemented
- [ ] Significant incident criteria defined
- [ ] Reporting procedures established

---

## Additional Resources

### Official NIS2 Resources

- **Directive Text**: https://eur-lex.europa.eu/eli/dir/2022/2555
- **Implementing Regulation**: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=OJ:L_202402764
- **National Authorities**: Contact your EU member state's CSIRT

### Complementary Security Measures

For full NIS2 compliance, also implement:
- Multi-factor authentication (MFA)
- Access control and least privilege
- Regular security updates and patching
- Encryption (data at rest and in transit)
- Business continuity planning
- Supply chain security
- Security awareness training
- Regular security audits

---

## Support

### Questions About This System

- **Email**: contact@itcms.gr
- **Support**: support@itcms.gr
- **Website**: https://itcms.gr

### Compliance Consulting

Need help with NIS2 compliance strategy?

- **Email**: contact@itcms.gr
- **Services**: Compliance assessments, gap analysis, implementation support

---

## Disclaimer

This system supports but does not guarantee NIS2 compliance. Organizations must:

- Implement comprehensive security controls beyond DNS monitoring
- Develop complete ISMS aligned with NIS2 requirements
- Establish incident response and reporting procedures
- Maintain appropriate documentation and evidence
- Engage with national competent authorities

**Consult legal and compliance professionals** for authoritative NIS2 guidance.

---

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
Licensed under ITCMS.GR Free License
SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0

---

*Part of the DirectAdmin DNS Change Alert System*
*https://itcms.gr*
