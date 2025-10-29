
# DirectAdmin Account & Domain Report (`scripts/da_report.sh`)

Generates a CSV with columns: `account,space_kb,domain,domain_php_version,hostname`.

## Usage

```bash
./scripts/da_report.sh
DA_ADMIN_CLI="/usr/local/directadmin/directadmin" OUTPUT_FILE="/root/da_report.csv" ./scripts/da_report.sh
```
