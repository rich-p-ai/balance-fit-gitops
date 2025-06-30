# Balance-fit GitOps Repository

This repository contains the Kubernetes manifests for the Balance-fit application using GitOps methodology with ArgoCD and Kustomize.

## Project Information

- **Organization**: Kohler Apps
- **Project**: Balance-fit  
- **Repository**: https://github.com/rich-p-ai/balance-fit-gitops
- **Environment**: Production OpenShift Cluster + DR Cluster
- **Deployment Tool**: ArgoCD
- **Configuration Management**: Kustomize

## Application Architecture

Balance-fit is a PHP Laravel application with the following components:

- **Frontend**: nginx reverse proxy (port 8030)
- **Backend**: PHP-FPM application (efit:9000) 
- **Database**: MySQL
- **Storage**: Persistent Volume Claims for application data

## Repository Structure

```
balance-fit-gitops/
├── base/                    # Base Kubernetes manifests
│   ├── nginx/              # nginx deployment and config
│   ├── php-app/            # PHP application deployment
│   ├── mysql/              # MySQL database
│   └── kustomization.yaml  # Base kustomization
├── overlays/               # Environment-specific configurations
│   ├── production/         # Production cluster (balance-fit-prd namespace)
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── patches/
│   │   └── secrets/
│   └── dr/                 # Disaster Recovery cluster
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── patches/
│       └── secrets/
├── docs/                   # Documentation
│   ├── deployment-guide.md
│   ├── troubleshooting.md
│   └── argocd-setup.md
└── README.md               # This file
```

## Deployment Process

### 1. Production Deployment
```bash
# Apply production configuration
kubectl apply -k overlays/production/

# Or via ArgoCD
argocd app create balance-fit-prod \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace balance-fit-prd
```

### 2. DR Deployment
```bash
# Apply DR configuration
kubectl apply -k overlays/dr/

# Or via ArgoCD
argocd app create balance-fit-dr \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/dr \
  --dest-server https://dr-cluster.kohlerco.com \
  --dest-namespace balance-fit-dr
```

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kohler-apps/balance-fit-gitops.git
   cd balance-fit-gitops
   ```

2. **Preview production deployment:**
   ```bash
   kubectl kustomize overlays/production/
   ```

3. **Deploy to production:**
   ```bash
   kubectl apply -k overlays/production/
   ```

## Configuration Management

### Environment Variables
- Production-specific configs are in `overlays/production/`
- DR-specific configs are in `overlays/dr/`
- Shared configs are in `base/`

### Secrets Management
- Secrets are managed per environment
- Use sealed-secrets or external-secrets for production
- Never commit plaintext secrets to this repository

## Monitoring and Health Checks

### Application Health
```bash
# Check nginx status
kubectl get pods -n balance-fit-prd -l app=nginx

# Test application endpoint
kubectl exec -n balance-fit-prd deployment/nginx -- curl -I http://localhost:8030
```

### ArgoCD Status
```bash
# Check ArgoCD application status
argocd app get balance-fit-prod
argocd app sync balance-fit-prod
```

## Recent Changes

### 2025-06-30: Initial GitOps Setup
- Migrated from manual deployment to GitOps structure
- Resolved nginx ImagePullBackOff issues
- Configured registry whitelisting
- Updated to nginxinc/nginx-unprivileged:1.25-alpine

## Migration to Bitbucket

This repository is currently on GitHub but will be migrated to Bitbucket after deployment testing is completed.

## Support

For issues or questions:
- **Environment**: Production OpenShift + DR
- **Namespace**: balance-fit-prd (production), balance-fit-dr (DR)
- **Team**: DevOps / Platform Engineering
- **Documentation**: See `docs/` folder

## License

Internal Kohler Application - Not for external distribution
