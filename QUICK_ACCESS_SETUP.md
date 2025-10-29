# Quick Access Setup - How to Give Push Access

> Simple guide to give someone write/push access to your repository

---

## For GitHub (Recommended)

### Step 1: Push Your Repository to GitHub

```bash
cd /home/claudetmp/GREPP/da_dns_change

# Initialize git
git init
git add .
git commit -m "Initial commit: DirectAdmin DNS Alert System v1.0.0"

# Create GitHub repository (replace YOUR-USERNAME with your GitHub username)
git remote add origin git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
git branch -M main
git push -u origin main
```

### Step 2: Give Push Access

**Via GitHub Web Interface:**

1. Go to: `https://github.com/YOUR-USERNAME/directadmin-dns-alerts`
2. Click **"Settings"** tab (top right)
3. Click **"Collaborators"** in left sidebar
4. Click **"Add people"** button
5. Enter their **GitHub username** or **email address**
6. Select **"Write"** permission (this gives push access)
7. Click **"Add [username] to this repository"**

**They will receive an email invitation to accept.**

### Step 3: They Clone and Work

Once they accept the invitation, they can:

```bash
# Clone the repository
git clone git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
cd directadmin-dns-alerts

# Make changes
nano scripts/hooks/dns_write_post.sh

# Commit and push
git add .
git commit -m "Update notification format"
git push origin main
```

---

## Permission Levels Explained

| Permission | Can View | Can Clone | Can Push | Can Merge PRs | Can Delete |
|------------|----------|-----------|----------|---------------|------------|
| **Read** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Write** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Admin** | ✅ | ✅ | ✅ | ✅ | ✅ |

**For push access, give "Write" or "Admin" permission.**

---

## For GitLab

### Step 1: Push to GitLab

```bash
cd /home/claudetmp/GREPP/da_dns_change

git init
git add .
git commit -m "Initial commit"

# Create project on GitLab, then:
git remote add origin git@gitlab.com:YOUR-USERNAME/directadmin-dns-alerts.git
git push -u origin main
```

### Step 2: Give Access

1. Go to your project on GitLab
2. Click **"Project information"** → **"Members"**
3. Click **"Invite members"**
4. Enter username/email
5. Choose role: **"Developer"** (can push) or **"Maintainer"** (full access)
6. Click **"Invite"**

---

## For Bitbucket

### Step 1: Push to Bitbucket

```bash
cd /home/claudetmp/GREPP/da_dns_change

git init
git add .
git commit -m "Initial commit"

git remote add origin git@bitbucket.org:YOUR-USERNAME/directadmin-dns-alerts.git
git push -u origin main
```

### Step 2: Give Access

1. Go to repository settings
2. Click **"User and group access"**
3. Add user
4. Choose **"Write"** permission
5. Click **"Add"**

---

## Using SSH Keys (Recommended)

For secure push access, both you and collaborators should use SSH keys:

### Generate SSH Key

```bash
# On their machine
ssh-keygen -t ed25519 -C "their-email@example.com"

# Display public key
cat ~/.ssh/id_ed25519.pub
```

### Add to GitHub

1. Copy the public key
2. Go to GitHub → Settings → SSH and GPG keys
3. Click "New SSH key"
4. Paste key and save

Now they can push using SSH URLs:
```bash
git clone git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
```

---

## Alternative: Deploy Keys (Read-Only)

For automated systems that only need read access:

### GitHub Deploy Keys

1. Repository → Settings → Deploy keys
2. Click "Add deploy key"
3. Paste public SSH key
4. **Don't check "Allow write access"** (for read-only)
5. Save

Use this for CI/CD that only needs to pull code.

---

## Multiple Contributors

### For Teams (2-5 people)

**Use Collaborators** (as described above)

### For Larger Teams (5+ people)

**Create GitHub Organization:**

```bash
# Benefits:
- Team management
- Granular permissions
- Better organization
- Shared billing
```

**Setup:**

1. Go to: https://github.com/organizations/new
2. Create organization (e.g., "itcms-gr")
3. Transfer repository to organization
4. Create teams:
   - **Developers** (Write access)
   - **Admins** (Admin access)
   - **Testers** (Read access)
5. Add members to teams

---

## Best Practices for Push Access

### 1. Use Branch Protection

Require pull requests instead of direct pushes to main:

```bash
# GitHub: Settings → Branches → Add rule
- Branch name: main
- ✅ Require pull request before merging
- ✅ Require approvals: 1
```

Then contributors:
```bash
# Create feature branch
git checkout -b feature/my-changes

# Make changes and push
git push origin feature/my-changes

# Create Pull Request on GitHub
# Main branch protected - can't push directly
```

### 2. Use CODEOWNERS File

Auto-request reviews from specific people:

```bash
# Create .github/CODEOWNERS
cat > .github/CODEOWNERS <<'EOF'
# Require approval from these users
* @YOUR-USERNAME

# Specific files
/scripts/hooks/ @YOUR-USERNAME @SECURITY-REVIEWER
/docs/ @DOCUMENTATION-TEAM
EOF
```

### 3. Limit Direct Push

Only give "Write" access to trusted contributors.
For others, they can:
1. Fork the repository
2. Make changes in their fork
3. Submit Pull Request
4. You review and merge

---

## Quick Commands for Contributors

Once they have push access:

```bash
# Clone repository
git clone git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
cd directadmin-dns-alerts

# Create branch for changes
git checkout -b fix/email-template

# Make changes
nano scripts/hooks/dns_write_post.sh

# Commit
git add scripts/hooks/dns_write_post.sh
git commit -m "Fix email template formatting"

# Push
git push origin fix/email-template

# Create Pull Request on GitHub (or push to main if allowed)
```

---

## Revoking Access

### Remove Collaborator

**GitHub:**
1. Settings → Collaborators
2. Find user
3. Click "Remove"

**They immediately lose push access.**

### Block User (if needed)

**GitHub:**
1. Settings → Moderation options → Blocked users
2. Block username
3. They cannot interact with repo at all

---

## Summary - Quickest Method

```bash
# 1. YOU: Initialize and push
cd /home/claudetmp/GREPP/da_dns_change
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
git push -u origin main

# 2. YOU: Give access
# GitHub → Repository → Settings → Collaborators → Add people
# Enter their GitHub username
# Choose "Write" permission

# 3. THEM: Accept invite (via email)

# 4. THEM: Clone and work
git clone git@github.com:YOUR-USERNAME/directadmin-dns-alerts.git
cd directadmin-dns-alerts
# ... make changes ...
git add .
git commit -m "My changes"
git push
```

---

## Troubleshooting

### "Permission denied (publickey)"

**Solution:**
```bash
# Check SSH key
ssh -T git@github.com

# If fails, add SSH key to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and add to GitHub → Settings → SSH keys
```

### "remote: Permission to repository denied"

**Solution:**
- Verify collaborator accepted invitation
- Check they have "Write" permission (not just "Read")
- Ensure they're pushing to correct repository

### "Updates were rejected"

**Solution:**
```bash
# Pull first
git pull origin main

# Then push
git push origin main
```

---

## Need Help?

**Email:** contact@itcms.gr
**Website:** https://itcms.gr

---

**Copyright © 2025 Antonios Voulvoulis, ITCMS.GR**
