# DirectAdmin Administration Scripts & Tools

> **Professional automation and monitoring tools for DirectAdmin control panel**

[![License](https://img.shields.io/badge/License-ITCMS%20Free-blue.svg)](LICENSE.txt)
[![DirectAdmin](https://img.shields.io/badge/DirectAdmin-Compatible-green.svg)](https://www.directadmin.com/)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-success.svg)]()

A comprehensive collection of production-ready scripts, hooks, and automation tools for DirectAdmin system administrators, hosting providers, and infrastructure operators. All tools are designed for enterprise use with proper error handling, logging, and security practices.

---

## 📁 Repository Structure

```
directadmin/
├── scripts/
│      └── dns/               # DNS Change Alert System (NIS2-compliant)
├── docs/                     # Documentations
├── LICENSES/                 # License files
├── LICENSE.txt               # ITCMS Free License
├── SECURITY.md               # Security policy
├── CONTRIBUTING.md           # Contribution guidelines
├── CHANGELOG.md              # Version history
└── README.md                 # This file
```

---

## 🚀 Available Tools

### 🌐 DNS Change Alert System

**Location**: [`scripts/examples/dns/`](scripts/dns/)

Real-time DNS monitoring and change notification system with NIS2 compliance support.

**Features**:
- 🔔 Instant email notifications when DNS records change
- 📊 Comprehensive domain and account reporting (CSV/JSON)
- 🌐 Multi-Server DNS support (clustered environments)
- 📋 Complete audit trail for compliance
- 🛡️ NIS2 Directive (EU) 2022/2555 compliance documentation

**Quick Start**:
```bash
cd scripts/examples/dns
cat README.md  # Read full documentation
sudo cp hooks/*.sh /usr/local/directadmin/scripts/custom/
sudo chmod 755 /usr/local/directadmin/scripts/custom/*.sh
```

**Documentation**:
- [DNS System README](scripts/dns/README.md)
- [Installation & Configuration](scripts/dns/docs/dns_change_notifications.md)
- [Reporting Guide](scripts/dns/docs/da_report.md)
- [NIS2 Compliance](scripts/dns/docs/NIS2.md)

**Use Cases**:
- Detect unauthorized DNS changes immediately
- Maintain NIS2/compliance audit trails
- Alert domain owners of DNS modifications
- Monitor multi-server DNS infrastructure
- Generate domain and account inventories

---

## 🎯 Quick Links by Use Case

### For Hosting Providers

- **DNS Monitoring**: [`scripts/examples/dns/`](scripts/dns/) - Alert customers automatically
- **Compliance**: [NIS2 Documentation](scripts/dns/docs/NIS2.md) - Meet EU requirements
- **Reporting**: DNS reporting tool for customer inventories

### For System Administrators

- **Automation**: Browse `scripts/` for DirectAdmin automation
- **Hooks**: Custom hooks extending DirectAdmin functionality
- **Monitoring**: Real-time notification systems

### For Security Teams

- **Incident Detection**: DNS change alerts for unauthorized modifications
- **Audit Trails**: Complete logging with timestamps and attribution
- **Compliance**: NIS2 and security documentation

---

## 🔧 Getting Started

### Prerequisites

- DirectAdmin 1.60+ installed
- Root or admin access
- Bash 4.0+
- Mail system configured (for notifications)

### Installation

```bash
# 1. Clone or download this repository
git clone https://github.com/YOUR-USERNAME/directadmin.git
cd directadmin

# 2. Choose your tool
ls scripts/examples/

# 3. Read tool documentation
cat scripts/examples/dns/README.md

# 4. Follow tool-specific installation instructions
cd scripts/examples/dns
# ... follow installation steps in README.md
```

---

## 📚 Documentation

### General Documentation

- **[Main README](README.md)** - This file (overview of all tools)
- **[License](LICENSE.txt)** - ITCMS.GR Free License terms
- **[Security Policy](SECURITY.md)** - Security guidelines
- **[Contributing](CONTRIBUTING.md)** - How to report issues
- **[Changelog](CHANGELOG.md)** - Version history

### Project-Specific Documentation

Each tool has its own documentation in its directory. See the README.md file in each project folder.

---

## 🛡️ Security

### Security Best Practices

- ✅ All scripts run with appropriate permissions
- ✅ Input validation and sanitization
- ✅ Secure file handling (no injection risks)
- ✅ Audit logging for all actions
- ✅ Regular security updates

### Reporting Security Issues

Found a vulnerability? Report responsibly:

- **Email**: security@itcms.gr
- **Policy**: See [SECURITY.md](SECURITY.md)
- **Do NOT** disclose publicly before we address it

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**What You Can Do**:
- ✅ Report bugs and issues
- ✅ Suggest features and improvements
- ✅ Test and provide feedback
- ✅ Improve documentation

**Note**: Due to licensing, direct code contributions work differently than typical open source projects.

---

## 📋 System Requirements

- **OS**: Linux (RHEL/CentOS/Rocky/Alma/Debian/Ubuntu)
- **DirectAdmin**: Version 1.60 or higher
- **Bash**: Version 4.0 or higher
- **Disk Space**: ~50MB for scripts and backups
- **Memory**: Minimal (scripts are lightweight)

---

## 🌍 Supported Platforms

| Platform | Status |
|----------|--------|
| RHEL 9 / Rocky Linux 9 | ✅ Fully Supported |
| CentOS 7/8 | ✅ Supported |
| AlmaLinux 8/9 | ✅ Supported |
| Debian 11/12 | ✅ Supported |
| Ubuntu 20.04/22.04/24.04 | ✅ Supported |

---

## 📜 License

**ITCMS.GR Free License – All Rights Reserved**

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR

This software is free for personal, internal, or commercial use. You may **not** modify, redistribute, or sell this software.

**SPDX License Identifier**: `LicenseRef-ITCMS-Free-1.0`

See [LICENSE.txt](LICENSE.txt) for full terms.

---

## 📞 Support

### Documentation & Help

- **Email**: contact@itcms.gr
- **Website**: https://itcms.gr
- **Support**: support@itcms.gr

### Professional Services

Need custom development, integration, or consulting?

- Custom scripts for your infrastructure
- Integration with monitoring/SIEM systems
- Team training on DirectAdmin automation
- Support contracts with SLA guarantees
- NIS2 compliance consulting

**Contact**: contact@itcms.gr

---

## 🗺️ Roadmap

### Current Version: 1.0.0

- ✅ DNS Change Alert System
- ✅ Domain/Account Reporting
- ✅ NIS2 Compliance Documentation
- ✅ Multi-Server DNS Support


## 🙏 Acknowledgments

- DirectAdmin team for excellent documentation
- Open source community for shell scripting best practices
- EU NIS2 working groups for security guidance
- Our users and testers for valuable feedback

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Latest Release**: v1.0.0 (2025-10-29)

---

## 💡 About ITCMS

**ITCMS.GR** develops professional tools for hosting providers, system administrators, and digital infrastructure operators.

**Other Projects**:
- ClientExec DNS Alert - DNS monitoring for ClientExec billing systems

**Website**: https://itcms.gr

---

<div align="center">

**Made with ❤️ by [ITCMS](https://itcms.gr)**

*Professional Tools for DirectAdmin Administration*

[Website](https://itcms.gr) • [Support](mailto:support@itcms.gr) • [Security](mailto:security@itcms.gr)

</div>
