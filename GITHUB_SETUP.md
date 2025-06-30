# GitHub Repository Setup Instructions

## 1. Create GitHub Repository

### Option A: Using GitHub CLI
```bash
# Install GitHub CLI if not already installed
# Then create repository under Kohler Apps organization
gh repo create kohler-apps/balance-fit-gitops --public --description "Balance-fit GitOps repository for ArgoCD deployment"
```

### Option B: Using GitHub Web Interface
1. Go to https://github.com/orgs/kohler-apps/repositories
2. Click "New repository"
3. Repository name: `balance-fit-gitops`
4. Description: "Balance-fit GitOps repository for ArgoCD deployment"
5. Set as Public or Private (as per organization policy)
6. Do NOT initialize with README (we already have one)
7. Click "Create repository"

## 2. Push to GitHub

```bash
# Add GitHub remote (replace URL with actual repository URL)
cd "C:\work\OneDrive - Kohler Co\Openshift\balance-fit-gitops"
git remote add origin https://github.com/kohler-apps/balance-fit-gitops.git

# Push to main branch
git branch -M main
git push -u origin main
```

## 3. Verify Repository Structure

After pushing, verify the repository contains:
- `base/` - Base Kubernetes manifests
- `overlays/production/` - Production configuration
- `overlays/dr/` - DR configuration  
- `docs/` - Documentation
- `README.md` - Main documentation

## 4. Next Steps

1. **Set up ArgoCD applications** using the configurations in `docs/argocd-setup.md`
2. **Deploy to production** using `overlays/production/`
3. **Test DR deployment** using `overlays/dr/`
4. **Configure secrets management** (sealed-secrets or external-secrets)
5. **Set up monitoring and alerting**
6. **Plan migration to Bitbucket** when ready

## 5. Repository Access

Ensure the following teams have access:
- **DevOps/Platform Engineering**: Admin access
- **Application Teams**: Read access
- **ArgoCD Service Account**: Read access

## 6. Branch Protection (Recommended)

Set up branch protection rules for `main` branch:
- Require pull request reviews
- Require status checks to pass
- Restrict who can push to matching branches
- Require branches to be up to date before merging
