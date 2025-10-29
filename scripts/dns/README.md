# DirectAdmin DNS Change Alert System

> **NIS2 Compliant DNS Monitoring & Audit Trail Solution**

[![License](https://img.shields.io/badge/License-ITCMS%20Free-blue.svg)](LICENSE.txt)
[![NIS2](https://img.shields.io/badge/NIS2-Compliant-success.svg)](docs/NIS2.md)

Automated DNS change detection and notification system for DirectAdmin. Provides real-time email alerts to domain owners when DNS records are modified, supporting **NIS2 Directive (EU) 2022/2555** compliance requirements.

---

## Features

- 🔔 **Real-time DNS monitoring** - Instant notifications when DNS records change
- 📧 **Email alerts** - Detailed diff reports showing old vs new values
- 🌐 **Multi-Server DNS** - Full support for DirectAdmin clustered environments
- 📊 **Reporting** - Generate CSV/JSON reports of all domains and accounts
- 📋 **Audit trail** - Complete backup history with timestamps
- 🛡️ **NIS2 compliance** - Documentation and tools for EU directive requirements

---

## Quick Install

```bash
# From directadmin root directory
cd scripts/examples/dns

# Install hooks
sudo install -d -m 0755 /usr/local/directadmin/scripts/custom
sudo cp all_pre.sh /usr/local/directadmin/scripts/custom/
sudo cp da_report.sh /usr/local/directadmin/scripts/custom/
sudo cp dns_raw_save_post.sh /usr/local/directadmin/scripts/custom/
sudo cp dns_write_post.sh /usr/local/directadmin/scripts/custom/
sudo chmod 755 /usr/local/directadmin/scripts/custom/all_pre.sh
sudo chmod 755 /usr/local/directadmin/scripts/custom/da_report.sh 
sudo chmod 755 /usr/local/directadmin/scripts/custom/dns_raw_save_post.sh 
sudo chmod 755 /usr/local/directadmin/scripts/custom/write_post.sh

# Install reporting tool
sudo cp da_report.sh /usr/local/bin/da_report
sudo chmod +x /usr/local/bin/da_report

# Test
sudo tail -f /var/log/da-hooks/dns_notify.log
```

---

## Documentation

- **[Installation & Configuration](docs/dns_change_notifications.md)** - Complete setup guide
- **[Reporting Guide](docs/da_report.md)** - Domain and account reporting
- **[NIS2 Compliance](docs/NIS2.md)** - Regulatory compliance documentation

---

## How It Works

1. Admin edits DNS via DirectAdmin
2. `all_pre.sh` backs up current zone
3. DirectAdmin saves changes
4. `dns_write_post.sh` compares old vs new, emails diff to domain owner
5. Complete audit trail maintained

---

## Support

- **Email**: contact@itcms.gr
- **Website**: https://itcms.gr
- **Documentation**: See `docs/` directory

---

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0

See [LICENSE.txt](LICENSE.txt) for full terms.
