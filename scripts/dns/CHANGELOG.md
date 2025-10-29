# Changelog

All notable changes to the DirectAdmin DNS Change Alert System will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-10-29

### Added

#### Core Features
- **DNS Change Detection**: Real-time monitoring of DNS zone modifications via DirectAdmin hooks
- **Email Notifications**: Automatic alerts to domain owners with unified diff showing changes
- **Multi-Server Support**: Cluster-aware notifications for DirectAdmin Multi-Server DNS
- **Audit Trail**: Complete backup history with timestamps and attribution
- **Domain Reporting**: CSV and JSON reports of all accounts and domains

#### Scripts
- `all_pre.sh`: Pre-hook to backup DNS zones before modifications
- `dns_write_post.sh`: Post-hook to detect changes and send notifications
- `dns_raw_save_post.sh`: Cluster-aware hook for raw zone transfers
- `da_report.sh`: Comprehensive reporting tool with CSV/JSON output

#### Documentation
- Complete README with installation and usage guide
- NIS2 compliance guide focused on DNS monitoring
- DNS change notification documentation
- Domain reporting documentation
- Contributing guidelines
- Security policy

#### Configuration
- Environment variable support for all scripts
- Configurable retention periods for backups and logs
- Customizable email templates and notification settings
- Support for custom DirectAdmin paths (RHEL/Debian compatibility)

#### Security
- Proper file permissions and access control
- CSV escaping to prevent injection
- Log rotation support
- Backup cleanup with configurable retention

### Features in Detail

**DNS Monitoring**:
- Detects CMD_DNS_ADMIN and CMD_DNS_CONTROL actions
- Backs up zones before modification
- Generates unified diffs showing exact changes
- Filters out SOA-only changes to reduce noise
- Supports both /var/named (RHEL) and /etc/bind (Debian) zone directories

**Email Notifications**:
- Sent to domain owner's registered email
- Falls back to admin email if owner email not found
- Includes security notice and NIS2 compliance information
- Shows complete before/after diff with context
- Truncates large diffs to prevent email size issues

**Reporting**:
- Lists all DirectAdmin accounts and domains
- Shows disk quotas and usage
- Reports PHP versions (user default)
- Resolves domain hostnames/IPs
- Supports both CSV and JSON output formats
- Environment variable configuration

**Multi-Server DNS**:
- Dedicated hook for cluster zone transfers
- Server role identification (primary/secondary)
- Cluster name tagging in logs
- Separate notification format for cluster operations

---


## Version History

### [1.0.0] - 2025-10-29
- Initial public release
- Core DNS monitoring functionality
- NIS2 compliance documentation
- Complete documentation suite

---

## Migration Guide

### From Manual DNS Monitoring

If you previously used manual DNS monitoring or custom scripts:

1. **Backup existing scripts**: Save any custom hooks you've created
2. **Install new hooks**: Follow installation guide in README.md
3. **Migrate configuration**: Transfer custom settings to environment variables
4. **Test thoroughly**: Verify notifications are working as expected
5. **Retire old scripts**: Remove custom implementations once verified

### Configuration Changes

**Version 1.0.0 introduces**:
- Standardized environment variables (see README)
- Consistent log file locations
- Unified backup directory structure

---

## Support

For questions about changes or upgrades:

- **Email**: contact@itcms.gr
- **Support**: support@itcms.gr
- **Website**: https://itcms.gr

---

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
