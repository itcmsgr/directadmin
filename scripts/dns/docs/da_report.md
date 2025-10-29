# DirectAdmin Domain & Account Reporting

> Generate comprehensive CSV and JSON reports of all DirectAdmin accounts, domains, quotas, and configurations.

---

## Overview

The `da_report.sh` script provides automated reporting capabilities for DirectAdmin installations, generating detailed inventories of:

- User accounts and quotas
- Domain listings and ownership
- PHP versions per account
- Hostname/IP resolution
- Disk space usage

This supports **NIS2 compliance** by maintaining an asset inventory of your DNS infrastructure.

---

## Features

- **Multiple Output Formats**: CSV (default) and JSON
- **Comprehensive Data**: Account, quota, domain, PHP version, hostname
- **Environment Overrides**: Configurable via environment variables
- **Error Handling**: Robust error checking and logging
- **Production Ready**: Safe defaults, proper escaping, logging

---

## Installation

### Quick Install

```bash
# Copy to system PATH
sudo cp scripts/da_report.sh /usr/local/bin/da_report
sudo chmod +x /usr/local/bin/da_report

# Verify installation
da_report --help
```

### Manual Installation

```bash
# Place script in custom location
sudo mkdir -p /opt/directadmin/scripts
sudo cp scripts/da_report.sh /opt/directadmin/scripts/
sudo chmod +x /opt/directadmin/scripts/da_report.sh

# Create symlink
sudo ln -s /opt/directadmin/scripts/da_report.sh /usr/local/bin/da_report
```

---

## Usage

### Basic Usage

```bash
# Generate default CSV report (current directory)
sudo da_report

# Output: da_report_20251029_143215.csv
```

### Custom Output Location

```bash
# Specify output file
sudo da_report -o /var/reports/domains.csv

# With timestamp
sudo da_report -o /var/reports/domains_$(date +%Y%m%d).csv
```

### JSON Output

```bash
# Generate JSON report
sudo da_report --json

# Output: da_report_20251029_143215.json

# JSON with custom path
sudo da_report --json -o /var/reports/domains.json
```

### Help

```bash
# Display usage information
da_report --help
```

---

## Command-Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-o FILE` | `--output FILE` | Specify output file path |
| `-j` | `--json` | Output in JSON format (requires `jq`) |
| `-h` | `--help` | Display help message |

---

## Environment Variables

Configure the script using environment variables:

### DirectAdmin Paths

```bash
# DirectAdmin CLI path (default: /usr/local/directadmin/dataskq)
export DA_ADMIN_CLI="/usr/local/directadmin/dataskq"

# DirectAdmin data directory (default: /usr/local/directadmin/data)
export DA_DATA_DIR="/usr/local/directadmin/data"
```

### Output Configuration

```bash
# Default output directory (default: current directory)
export OUTPUT_DIR="/var/reports/directadmin"
```

### Persistent Configuration

```bash
# Create configuration file
sudo tee /etc/default/da-reports <<EOF
DA_ADMIN_CLI="/usr/local/directadmin/dataskq"
DA_DATA_DIR="/usr/local/directadmin/data"
OUTPUT_DIR="/var/reports/directadmin"
EOF

# Source before running
source /etc/default/da-reports
da_report
```

---

## Output Formats

### CSV Format

**Header:**
```csv
account,space_kb,domain,domain_php_version,hostname
```

**Example Rows:**
```csv
user1,524288,example.com,php80,192.0.2.1
user1,524288,shop.example.com,php80,192.0.2.1
user2,1048576,another.com,php74,192.0.2.50
user2,1048576,blog.another.com,php74,192.0.2.50
admin,2097152,server.example.com,default,192.0.2.100
```

**Fields:**

| Field | Description | Example |
|-------|-------------|---------|
| `account` | DirectAdmin username | `user1` |
| `space_kb` | Disk quota in kilobytes | `524288` (512 MB) |
| `domain` | Domain name | `example.com` |
| `domain_php_version` | PHP version (user default) | `php80`, `php74`, `default` |
| `hostname` | Resolved IP address | `192.0.2.1`, `unresolved` |

### JSON Format

**Example:**
```json
[
  {
    "account": "user1",
    "space_kb": "524288",
    "domain": "example.com",
    "domain_php_version": "php80",
    "hostname": "192.0.2.1"
  },
  {
    "account": "user2",
    "space_kb": "1048576",
    "domain": "another.com",
    "domain_php_version": "php74",
    "hostname": "192.0.2.50"
  }
]
```

---

## Examples

### Daily Report Generation

```bash
#!/bin/bash
# /etc/cron.daily/da-report

OUTPUT_DIR="/var/reports/directadmin"
TIMESTAMP=$(date +%Y%m%d)

# Generate CSV report
/usr/local/bin/da_report -o "${OUTPUT_DIR}/domains_${TIMESTAMP}.csv"

# Generate JSON report
/usr/local/bin/da_report --json -o "${OUTPUT_DIR}/domains_${TIMESTAMP}.json"

# Clean up old reports (keep 90 days)
find "$OUTPUT_DIR" -name "domains_*.csv" -mtime +90 -delete
find "$OUTPUT_DIR" -name "domains_*.json" -mtime +90 -delete
```

### Weekly Summary Email

```bash
#!/bin/bash
# /etc/cron.weekly/da-report-email

REPORT_FILE="/tmp/da_domains_$(date +%Y%m%d).csv"
ADMIN_EMAIL="admin@example.com"

# Generate report
da_report -o "$REPORT_FILE"

# Count domains and accounts
ACCOUNT_COUNT=$(tail -n +2 "$REPORT_FILE" | cut -d, -f1 | sort -u | wc -l)
DOMAIN_COUNT=$(tail -n +2 "$REPORT_FILE" | wc -l)

# Send email with attachment
{
    echo "Subject: Weekly DirectAdmin Report"
    echo "To: $ADMIN_EMAIL"
    echo "Content-Type: text/plain; charset=UTF-8"
    echo ""
    echo "Weekly DirectAdmin Domain Report"
    echo "================================"
    echo ""
    echo "Total Accounts: $ACCOUNT_COUNT"
    echo "Total Domains:  $DOMAIN_COUNT"
    echo ""
    echo "Full report attached."
} | sendmail -t

# Cleanup
rm -f "$REPORT_FILE"
```

### Integration with Monitoring

```bash
#!/bin/bash
# Send report to monitoring system

# Generate JSON report
REPORT_FILE="/tmp/da_report_$(date +%s).json"
da_report --json -o "$REPORT_FILE"

# Send to monitoring API
curl -X POST https://monitoring.example.com/api/directadmin \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    --data-binary "@${REPORT_FILE}"

# Cleanup
rm -f "$REPORT_FILE"
```

### Custom Processing

```bash
#!/bin/bash
# Analyze domains per account

CSV_FILE="$(da_report -o /tmp/da_report.csv 2>&1 | grep 'Output file:' | awk '{print $3}')"

echo "Domains per Account:"
echo "===================="

tail -n +2 "$CSV_FILE" | \
    cut -d, -f1 | \
    sort | \
    uniq -c | \
    sort -rn | \
    awk '{printf "%-20s %d domains\n", $2, $1}'
```

---

## Data Sources

The script extracts data from DirectAdmin's filesystem:

### User List

```bash
# Via DirectAdmin CLI
echo "CMD_API_SHOW_USERS" | /usr/local/directadmin/dataskq
```

### User Quota

```bash
# File: /usr/local/directadmin/data/users/<username>/user.usage
# Format: quota=524288
```

### User Domains

```bash
# File: /usr/local/directadmin/data/users/<username>/domains.list
# Format: One domain per line
```

### PHP Version

```bash
# File: /usr/local/directadmin/data/users/<username>/user.conf
# Format: php1_select=php80
```

### Domain Resolution

```bash
# Using 'dig' command
dig +short example.com A | head -n1
```

---

## Troubleshooting

### Permission Denied

**Problem**: `Cannot read DirectAdmin CLI`

**Solution**:
```bash
# Run with sudo
sudo da_report

# Or add current user to directadmin group
sudo usermod -aG directadmin $(whoami)
```

### Empty Report

**Problem**: Report generated but no data

**Solutions**:

```bash
# 1. Verify DirectAdmin CLI path
ls -l /usr/local/directadmin/dataskq

# 2. Test CLI directly
echo "CMD_API_SHOW_USERS" | sudo /usr/local/directadmin/dataskq

# 3. Check data directory
ls -la /usr/local/directadmin/data/users/

# 4. Verify script has execute permission
chmod +x /usr/local/bin/da_report
```

### JSON Requires jq

**Problem**: `jq is required for JSON output but not found`

**Solution**:
```bash
# RHEL/CentOS/Rocky:
sudo yum install jq

# Debian/Ubuntu:
sudo apt-get install jq

# Verify installation
jq --version
```

### Hostname Resolution Slow

**Problem**: Report generation takes too long

**Cause**: DNS resolution for each domain

**Solution**:
```bash
# Skip hostname resolution by modifying script
# Comment out the get_domain_hostname call
# Or set a timeout for dig

# Alternative: Generate report without hostnames,
# then resolve in parallel batch:
tail -n +2 report.csv | cut -d, -f3 | \
    xargs -P 10 -I {} dig +short {} A
```

### CSV Parsing Issues

**Problem**: CSV contains commas in fields

**Solution**: The script properly escapes CSV fields. Ensure you're using a CSV-aware parser:

```bash
# Python
import csv
with open('report.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row)

# awk (with proper CSV support)
awk -F',' '{print $1}' report.csv  # May break on quoted fields

# Use csvkit instead
csvcut -c account report.csv
```

---

## Advanced Usage

### Filter by Account

```bash
# Generate report, filter for specific user
da_report -o /tmp/all_domains.csv
grep "^user1," /tmp/all_domains.csv
```

### Calculate Total Disk Usage

```bash
# Sum all disk usage
tail -n +2 report.csv | \
    cut -d, -f2 | \
    awk '{sum+=$1} END {print sum/1024/1024 " GB"}'
```

### Find Unresolved Domains

```bash
# List domains with no DNS resolution
tail -n +2 report.csv | \
    grep ",unresolved$" | \
    cut -d, -f3
```

### Export to Database

```bash
#!/bin/bash
# Import CSV into PostgreSQL

REPORT_FILE=$(da_report -o /tmp/da_report.csv 2>&1 | grep 'Output file' | awk '{print $3}')

psql -U admin -d inventory <<SQL
CREATE TABLE IF NOT EXISTS directadmin_domains (
    account VARCHAR(255),
    space_kb BIGINT,
    domain VARCHAR(255),
    php_version VARCHAR(50),
    hostname VARCHAR(255),
    report_date DATE DEFAULT CURRENT_DATE
);

COPY directadmin_domains(account, space_kb, domain, php_version, hostname)
FROM '${REPORT_FILE}'
WITH (FORMAT csv, HEADER true);
SQL
```

---

## NIS2 Compliance

### Asset Inventory Requirement

NIS2 Directive requires organizations to maintain an up-to-date inventory of assets. This script helps fulfill that requirement for DNS infrastructure.

### Recommended Practices

1. **Regular Reporting**: Generate reports daily or weekly
2. **Version Control**: Store reports in version-controlled repository
3. **Change Detection**: Compare reports to detect additions/removals
4. **Documentation**: Document reporting procedures in your ISMS
5. **Retention**: Keep reports according to regulatory retention periods

### Sample Compliance Procedure

```bash
#!/bin/bash
# NIS2 Asset Inventory - Daily Report

REPORT_DIR="/var/compliance/nis2/asset-inventory"
DATE=$(date +%Y%m%d)
PREVIOUS_REPORT=$(ls -t $REPORT_DIR/domains_*.csv 2>/dev/null | head -n1)

# Generate current report
CURRENT_REPORT="${REPORT_DIR}/domains_${DATE}.csv"
da_report -o "$CURRENT_REPORT"

# If previous report exists, compare
if [ -n "$PREVIOUS_REPORT" ]; then
    DIFF_FILE="${REPORT_DIR}/changes_${DATE}.diff"
    diff "$PREVIOUS_REPORT" "$CURRENT_REPORT" > "$DIFF_FILE"

    if [ -s "$DIFF_FILE" ]; then
        # Changes detected, send alert
        mail -s "NIS2 Asset Inventory Changes Detected" \
            compliance@example.com < "$DIFF_FILE"
    fi
fi

# Git commit for version control
cd "$REPORT_DIR"
git add "$CURRENT_REPORT"
git commit -m "Daily asset inventory - $DATE"
```

---

## Performance

### Benchmarks

Typical performance on a server with 100 accounts and 500 domains:

- **CSV Generation**: ~30 seconds
- **JSON Generation**: ~35 seconds (includes jq formatting)

Performance factors:
- Number of accounts/domains
- DNS resolution time (major factor)
- Disk I/O speed
- CPU performance

### Optimization Tips

1. **Cache DNS Results**: Cache hostname resolutions to speed up subsequent runs
2. **Parallel Processing**: Modify script to resolve hostnames in parallel
3. **Skip Hostname Resolution**: Comment out hostname lookup for faster reports
4. **Run During Off-Peak**: Schedule reports during low-traffic periods

---

## Integration Examples

### Prometheus Exporter

```bash
#!/bin/bash
# Export metrics for Prometheus

REPORT_FILE="/tmp/da_metrics.csv"
da_report -o "$REPORT_FILE"

ACCOUNT_COUNT=$(tail -n +2 "$REPORT_FILE" | cut -d, -f1 | sort -u | wc -l)
DOMAIN_COUNT=$(tail -n +2 "$REPORT_FILE" | wc -l)
TOTAL_SPACE=$(tail -n +2 "$REPORT_FILE" | cut -d, -f2 | awk '{sum+=$1} END {print sum}')

cat <<EOF > /var/lib/node_exporter/textfile_collector/directadmin.prom
# HELP directadmin_accounts Total number of DirectAdmin accounts
# TYPE directadmin_accounts gauge
directadmin_accounts $ACCOUNT_COUNT

# HELP directadmin_domains Total number of domains
# TYPE directadmin_domains gauge
directadmin_domains $DOMAIN_COUNT

# HELP directadmin_space_kb Total disk space usage in KB
# TYPE directadmin_space_kb gauge
directadmin_space_kb $TOTAL_SPACE
EOF
```

### Grafana Dashboard

Use the JSON output with Grafana's JSON data source:

```bash
# Generate JSON for Grafana
da_report --json -o /var/www/html/api/directadmin/domains.json

# Configure Grafana JSON data source:
# URL: http://yourserver.com/api/directadmin/domains.json
```

---

## Support

### Documentation

- Main README: [../README.md](../README.md)
- DNS Monitoring: [dns_change_notifications.md](dns_change_notifications.md)
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
