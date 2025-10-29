# Git Repository Setup & Access Guide

> How to initialize Git, share access, and integrate with existing projects

---

## Quick Start - Initialize Git Repository

### Step 1: Initialize Git

```bash
cd /home/claudetmp/GREPP/da_dns_change

# Initialize git repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: DirectAdmin DNS Change Alert System v1.0.0

- DNS change detection and notification system
- Email alerts with diff reports
- Multi-Server DNS support
- Account and domain reporting (CSV/JSON)
- NIS2 compliance documentation
- Complete hook scripts and documentation

SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
Copyright (c) 2025 Antonios Voulvoulis"
```

### Step 2: Create GitHub Repository

**Option A: Via GitHub Web Interface**

1. Go to https://github.com
2. Click "+" → "New repository"
3. Repository name: `directadmin-dns-alerts` (or your choice)
4. Description: "NIS2-compliant DNS change monitoring for DirectAdmin"
5. **Important**: Choose "Private" if you want to control access
6. **Don't initialize** with README (you already have one)
7. Click "Create repository"

**Option B: Via GitHub CLI**

```bash
# Install GitHub CLI if needed
# https://cli.github.com/

# Login
gh auth login

# Create repository
gh repo create directadmin-dns-alerts \
    --private \
    --description "NIS2-compliant DNS change monitoring for DirectAdmin" \
    --source=. \
    --push
```

### Step 3: Connect to GitHub

```bash
# Add remote origin (replace with your GitHub URL)
git remote add origin https://github.com/YOUR-USERNAME/directadmin-dns-alerts.git

# Or with SSH (recommended)
git remote add origin git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## Giving Access to Repository

### GitHub - Collaborator Access

**For Private Repositories:**

1. Go to your repository on GitHub
2. Click "Settings" tab
3. Click "Collaborators and teams" (left sidebar)
4. Click "Add people"
5. Enter GitHub username or email
6. Choose permission level:
   - **Read**: View only
   - **Write**: View and create branches/PRs (but can't accept them)
   - **Admin**: Full access

**Permission Levels Explained:**

| Level | Can View | Can Clone | Can Push | Can Change Settings |
|-------|----------|-----------|----------|---------------------|
| Read | ✅ | ✅ | ❌ | ❌ |
| Write | ✅ | ✅ | ✅ | ❌ |
| Admin | ✅ | ✅ | ✅ | ✅ |

### GitHub - Organization Access

If you want team access:

1. Create GitHub Organization
2. Add repository to organization
3. Create teams (e.g., "DNS Team", "Admins")
4. Assign team permissions
5. Add members to teams

### GitLab / Bitbucket

Similar process:
- **GitLab**: Settings → Members → Invite member
- **Bitbucket**: Repository settings → User and group access

---

## Combining with Existing Project

### Option 1: Separate Repositories (Recommended)

Keep projects separate but reference each other:

```bash
# Your existing project structure
/home/claudetmp/
├── CLIENTEXEC_ALRT_MODULE/    # Existing ClientExec module
└── GREPP/
    └── da_dns_change/          # New DirectAdmin project

# Push each as separate repo
cd /home/claudetmp/CLIENTEXEC_ALRT_MODULE
git push

cd /home/claudetmp/GREPP/da_dns_change
git push
```

**Benefits**:
- Independent version control
- Separate issue tracking
- Easier to maintain
- Each project can have different collaborators

### Option 2: Monorepo (All Projects Together)

Combine everything in one repository:

```bash
# Create parent directory
mkdir -p /home/claudetmp/GREPP/itcms-hosting-tools
cd /home/claudetmp/GREPP/itcms-hosting-tools

# Initialize git
git init

# Move projects into subdirectories
mkdir -p projects
mv /home/claudetmp/CLIENTEXEC_ALRT_MODULE projects/clientexec-dns-alert
cp -r /home/claudetmp/GREPP/da_dns_change projects/directadmin-dns-alert

# Create main README
cat > README.md <<'EOF'
# ITCMS Hosting Tools

Collection of NIS2-compliant DNS monitoring tools for hosting control panels.

## Projects

- **[ClientExec DNS Alert](projects/clientexec-dns-alert/)** - DNS monitoring for ClientExec
- **[DirectAdmin DNS Alert](projects/directadmin-dns-alert/)** - DNS monitoring for DirectAdmin

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0
EOF

# Commit and push
git add .
git commit -m "Initial commit: ITCMS Hosting Tools monorepo"
git remote add origin git@github.com:YOUR-USERNAME/itcms-hosting-tools.git
git push -u origin main
```

### Option 3: Git Submodules

Keep separate repos but link them:

```bash
# Create parent repo
mkdir -p /home/claudetmp/GREPP/itcms-hosting-suite
cd /home/claudetmp/GREPP/itcms-hosting-suite
git init

# Add existing projects as submodules
git submodule add https://github.com/YOUR-USERNAME/clientexec-dns-alert.git modules/clientexec
git submodule add https://github.com/YOUR-USERNAME/directadmin-dns-alert.git modules/directadmin

# Create main README linking to submodules
cat > README.md <<'EOF'
# ITCMS Hosting Suite

## Modules

- [ClientExec DNS Alert](modules/clientexec/)
- [DirectAdmin DNS Alert](modules/directadmin/)

## Installation

```bash
git clone --recurse-submodules https://github.com/YOUR-USERNAME/itcms-hosting-suite.git
```
EOF

# Commit
git add .
git commit -m "Add ITCMS hosting modules"
git push -u origin main
```

---

## Recommended Structure for Your Use Case

Based on your description, I recommend:

```
GitHub Organization: itcms-gr (or your org)
├── clientexec-dns-alert          # Existing ClientExec module
├── directadmin-dns-alert         # New DirectAdmin module
└── hosting-tools-docs            # Shared documentation (optional)
```

**Why?**
- Each tool is independent
- Easy to give different access levels
- Users can choose which tool they need
- Easier issue tracking per project
- Can version independently

---

## Step-by-Step: Integrate with Existing Project

### 1. Push DirectAdmin Project

```bash
cd /home/claudetmp/GREPP/da_dns_change

# Initialize if not done
git init
git add .
git commit -m "Initial commit: DirectAdmin DNS Alert System v1.0.0"

# Create GitHub repo and push
gh repo create directadmin-dns-alert --private --source=. --push

# Or manually
git remote add origin git@github.com:YOUR-USERNAME/directadmin-dns-alert.git
git push -u origin main
```

### 2. Update Existing ClientExec Project

```bash
cd /home/claudetmp/CLIENTEXEC_ALRT_MODULE

# Reference the new project in README
cat >> README.md <<'EOF'

## Related Projects

Looking for DirectAdmin DNS monitoring? Check out [DirectAdmin DNS Alert](https://github.com/YOUR-USERNAME/directadmin-dns-alert)

## ITCMS Product Family

- **ClientExec DNS Alert** - This project
- **[DirectAdmin DNS Alert](https://github.com/YOUR-USERNAME/directadmin-dns-alert)** - DNS monitoring for DirectAdmin
EOF

# Commit and push
git add README.md
git commit -m "Add reference to DirectAdmin DNS Alert project"
git push
```

### 3. Create Overview Repository (Optional)

```bash
mkdir -p /home/claudetmp/GREPP/itcms-dns-tools
cd /home/claudetmp/GREPP/itcms-dns-tools
git init

cat > README.md <<'EOF'
# ITCMS DNS Monitoring Tools

NIS2-compliant DNS change detection and alerting for hosting control panels.

## Available Tools

### 🔹 ClientExec DNS Alert
**For:** ClientExec hosting billing system
**Features:** DNS monitoring, email alerts, audit trail
**Repository:** [clientexec-dns-alert](https://github.com/YOUR-USERNAME/clientexec-dns-alert)

### 🔹 DirectAdmin DNS Alert
**For:** DirectAdmin hosting control panel
**Features:** Real-time DNS monitoring, multi-server support, comprehensive reporting
**Repository:** [directadmin-dns-alert](https://github.com/YOUR-USERNAME/directadmin-dns-alert)

## Installation

Choose the appropriate tool for your hosting platform and follow the installation guide in its repository.

## Support

- **Email:** contact@itcms.gr
- **Website:** https://itcms.gr

## License

Copyright © 2025 Antonios Voulvoulis, ITCMS.GR
All projects licensed under ITCMS.GR Free License
EOF

git add .
git commit -m "Initial commit: ITCMS DNS Tools overview"
gh repo create itcms-dns-tools --public --source=. --push
```

---

## Managing Access - Best Practices

### GitHub Teams Approach

```
Organization: itcms-gr
│
├── Teams:
│   ├── Core Team (Admin access to all repos)
│   ├── Contributors (Write access to specific repos)
│   └── Testers (Read access for testing)
│
└── Repositories:
    ├── clientexec-dns-alert
    ├── directadmin-dns-alert
    └── itcms-dns-tools
```

**Setup:**

1. Create GitHub Organization: https://github.com/organizations/new
2. Transfer repositories to organization
3. Create teams and assign permissions
4. Invite members to teams

### Individual Repository Access

For contractors or external collaborators:

```bash
# Give specific person access
# Repository → Settings → Collaborators → Add people

# Time-limited access:
# Add person, then remove after project completion
```

---

## Protecting Your Repositories

### Branch Protection

```bash
# Via GitHub web interface:
# Settings → Branches → Add rule

# Protect main branch:
- Require pull request reviews
- Require status checks
- Require branches to be up to date
- Include administrators (optional)
```

### Access Tokens (for CI/CD)

```bash
# GitHub → Settings → Developer settings → Personal access tokens

# Create token with limited scope:
- Read-only for public access
- Write for automated deployments
- Store securely (never commit to repo)
```

---

## Quick Commands Reference

### Daily Git Operations

```bash
# Check status
git status

# Pull latest changes
git pull

# Create branch for new feature
git checkout -b feature/webhook-notifications

# Commit changes
git add .
git commit -m "Add webhook notification support"

# Push branch
git push -u origin feature/webhook-notifications

# Merge to main
git checkout main
git merge feature/webhook-notifications
git push
```

### Sharing Repository

```bash
# Clone URL for others (HTTPS)
https://github.com/YOUR-USERNAME/directadmin-dns-alert.git

# Clone URL for others (SSH)
git@github.com:YOUR-USERNAME/directadmin-dns-alert.git

# They clone with:
git clone https://github.com/YOUR-USERNAME/directadmin-dns-alert.git
cd directadmin-dns-alert
```

---

## Next Steps

1. **Initialize Git**: Run commands in "Step 1: Initialize Git"
2. **Create GitHub repo**: Follow "Step 2: Create GitHub Repository"
3. **Push code**: Execute "Step 3: Connect to GitHub"
4. **Add collaborators**: Use "Giving Access to Repository" section
5. **Integrate projects**: Choose an option from "Combining with Existing Project"
6. **Set up protection**: Implement "Protecting Your Repositories" if needed

---

## Questions?

**Email:** contact@itcms.gr
**Website:** https://itcms.gr

---

**Copyright © 2025 Antonios Voulvoulis, ITCMS.GR**
**SPDX-License-Identifier: LicenseRef-ITCMS-Free-1.0**
