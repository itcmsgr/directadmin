# Contributing to DirectAdmin DNS Change Alert System

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

---

## Important Note About Licensing

This project is licensed under the **ITCMS.GR Free License (LicenseRef-ITCMS-Free-1.0)**, which has specific restrictions:

- ✅ You may use this software freely
- ❌ You may NOT modify, redistribute, or sell the software as
- ❌ Source code contributions are NOT accepted via pull requests

### How You Can Contribute

Since the license restricts modifications and redistribution, contributions work differently:

1. **Bug Reports**: Report issues you encounter
2. **Feature Requests**: Suggest improvements
3. **Documentation Feedback**: Point out unclear or incorrect docs
4. **Testing**: Test on different environments and report results
5. **Ideas & Discussion**: Share your use cases and suggestions

All contributions will be reviewed and potentially implemented by the project maintainer.

---

## Ways to Contribute

### 1. Bug Reports

Found a bug? Please report it!

**Before Reporting**:
- Check existing issues to avoid duplicates
- Verify it's reproducible
- Collect relevant information

**Good Bug Report Includes**:
- Clear title describing the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details:
  - DirectAdmin version
  - OS and version (RHEL/CentOS/Debian/Ubuntu)
  - Bash version
  - Relevant configuration

**Example Bug Report**:

```markdown
**Title**: Email notifications not sent on Debian 12

**Description**:
DNS changes are detected and logged, but email notifications are not being sent to domain owners.

**Steps to Reproduce**:
1. Install hooks on Debian 12 system
2. Edit DNS via DirectAdmin
3. Check logs - shows "Notification sent" but no email arrives

**Expected**: Email notification sent to domain owner
**Actual**: No email received

**Environment**:
- DirectAdmin: 1.65.4
- OS: Debian 12 (bookworm)
- Bash: 5.2.15
- Zone directory: /etc/bind

**Logs**:
```
[2025-10-29 14:32:15] Notification sent via 'mail' to owner@example.com
```

**Additional Info**:
mailx is installed and `mail` command works when tested manually.
```

### 2. Feature Requests

Have an idea for improvement?

**Good Feature Request Includes**:
- Clear description of the feature
- Use case explaining why it's needed
- Example of how it would work
- Potential implementation ideas (optional)

**Example Feature Request**:

```markdown
**Title**: Add Slack webhook notifications

**Description**:
Send DNS change notifications to Slack channel in addition to email.

**Use Case**:
Our team monitors infrastructure changes in Slack. Having DNS alerts
in our #infrastructure channel would provide better visibility.

**Proposed Behavior**:
1. Add SLACK_WEBHOOK_URL environment variable
2. When DNS changes, post to Slack with formatted message
3. Include domain, admin user, and link to diff

**Implementation Ideas**:
Use curl to POST to Slack webhook API with JSON payload.
Could reuse existing notification logic from email.
```

### 3. Documentation Improvements

Found unclear or incorrect documentation?

**Report**:
- Which document has the issue
- What's unclear or wrong
- Suggested correction or improvement

**Example Documentation Issue**:

```markdown
**File**: docs/dns_change_notifications.md
**Section**: "Email Recipients"
**Issue**: Instructions don't mention what happens if domainowners file is missing
**Suggestion**: Add troubleshooting section for missing domainowners file
```

### 4. Testing

Help test on different environments!

**Useful Testing**:
- Different DirectAdmin versions
- Different Linux distributions
- Multi-Server DNS configurations
- Edge cases (many domains, large zones, etc.)

**Test Report Format**:

```markdown
**Environment**:
- DirectAdmin: 1.64.2
- OS: Rocky Linux 9
- Domains: 500+

**Tests Performed**:
- [x] DNS change detection
- [x] Email notifications
- [x] Backup creation
- [x] Log rotation
- [ ] Cluster mode (not applicable)

**Results**:
All tests passed. System handled 50 simultaneous DNS changes without issues.

**Notes**:
Hostname resolution slows down da_report.sh with 500+ domains.
Consider adding parallel DNS resolution.
```

---

## How to Submit

### Create an Issue

1. Visit the project's issue tracker
2. Click "New Issue"
3. Choose appropriate template (Bug Report / Feature Request / Documentation)
4. Fill out all sections
5. Submit

### Email Reports

Alternatively, email reports to:
- **General**: contact@itcms.gr
- **Security Issues**: security@itcms.gr

---

## Code of Conduct

### Our Standards

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Constructive**: Provide helpful feedback
- **Be Professional**: Keep discussions on-topic
- **Be Patient**: Maintainers are volunteers

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Off-topic or spam content
- Sharing others' private information

### Enforcement

Violations may result in:
1. Warning
2. Temporary ban
3. Permanent ban

Report violations to: contact@itcms.gr

---

## Questions?

Have questions about contributing?

- **Email**: contact@itcms.gr
- **Website**: https://itcms.gr

---

## Recognition

Contributors will be acknowledged in:
- CHANGELOG.md (for significant contributions)
- Special thanks section (for testers and reporters)

---

## License

By submitting bug reports, feature requests, or other feedback, you agree that:

- Your contributions are provided freely
- The project maintainer may use your feedback to improve the software
- You retain no rights to implementations based on your suggestions
- The project remains under ITCMS.GR Free License

---

Thank you for helping improve the DirectAdmin DNS Change Alert System!

---

**Copyright © 2025 Antonios Voulvoulis, ITCMS.GR**
**SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0**
