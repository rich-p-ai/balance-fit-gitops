# ArgoCD Setup Guide for Balance-fit

This guide explains how to configure ArgoCD for the Balance-fit application deployment.

## Prerequisites

- ArgoCD installed on OpenShift cluster
- Access to ArgoCD UI and CLI
- GitHub repository access

## ArgoCD Application Configuration

### 1. Production Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: balance-fit-prod
  namespace: argocd
  labels:
    app.kubernetes.io/name: balance-fit
    environment: production
spec:
  project: default
  source:
    repoURL: https://github.com/kohler-apps/balance-fit-gitops
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: balance-fit-prd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 2. DR Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: balance-fit-dr
  namespace: argocd
  labels:
    app.kubernetes.io/name: balance-fit
    environment: dr
spec:
  project: default
  source:
    repoURL: https://github.com/kohler-apps/balance-fit-gitops
    targetRevision: main
    path: overlays/dr
  destination:
    server: https://ocp-dr.kohlerco.com:6443
    namespace: balance-fit-dr
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 3
```

## CLI Commands

### Create Applications
```bash
# Production
argocd app create balance-fit-prod \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace balance-fit-prd \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --sync-option CreateNamespace=true

# DR
argocd app create balance-fit-dr \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/dr \
  --dest-server https://ocp-dr.kohlerco.com:6443 \
  --dest-namespace balance-fit-dr \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Management Commands
```bash
# List applications
argocd app list

# Get application details
argocd app get balance-fit-prod

# Sync application
argocd app sync balance-fit-prod

# View application logs
argocd app logs balance-fit-prod

# Delete application
argocd app delete balance-fit-prod
```

## ArgoCD Project Configuration

### Create Dedicated Project
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: balance-fit
  namespace: argocd
spec:
  description: Balance-fit Application Project
  sourceRepos:
  - 'https://github.com/kohler-apps/balance-fit-gitops'
  destinations:
  - namespace: balance-fit-prd
    server: https://kubernetes.default.svc
  - namespace: balance-fit-dr
    server: https://ocp-dr.kohlerco.com:6443
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: ''
    kind: '*'
  - group: 'apps'
    kind: '*'
  - group: 'route.openshift.io'
    kind: '*'
  roles:
  - name: admin
    policies:
    - p, proj:balance-fit:admin, applications, *, balance-fit/*, allow
    - p, proj:balance-fit:admin, repositories, *, *, allow
    groups:
    - balance-fit-admins
```

## Repository Configuration

### Private Repository Access
```bash
# Add repository with SSH key
argocd repo add git@github.com:kohler-apps/balance-fit-gitops.git \
  --ssh-private-key-path ~/.ssh/id_rsa

# Add repository with HTTPS
argocd repo add https://github.com/kohler-apps/balance-fit-gitops.git \
  --username your-username \
  --password your-token
```

## Health Checks and Monitoring

### Application Health
```bash
# Check application health
argocd app get balance-fit-prod --show-operation

# Watch application sync
argocd app sync balance-fit-prod --watch

# View application resources
argocd app resources balance-fit-prod
```

### Sync Waves
Add sync waves to control deployment order:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy first
```

Recommended sync order:
1. Namespace (wave 0)
2. ConfigMaps and Secrets (wave 1)
3. PVCs (wave 2)
4. Deployments and Services (wave 3)
5. Routes (wave 4)

## Notifications

### Slack Integration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is now running new version.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

## Troubleshooting

### Common Issues

#### 1. Sync Failures
```bash
# Check application events
argocd app get balance-fit-prod --show-operation

# Manual sync with force
argocd app sync balance-fit-prod --force
```

#### 2. Resource Conflicts
```bash
# Prune extra resources
argocd app sync balance-fit-prod --prune

# Reset application
argocd app actions run balance-fit-prod restart --kind Deployment
```

#### 3. Permission Issues
```bash
# Check RBAC
kubectl auth can-i create deployment --namespace balance-fit-prd --as=system:serviceaccount:argocd:argocd-application-controller
```

## Best Practices

1. **Use Application Sets**: For managing multiple environments
2. **Implement Sync Waves**: Control deployment order
3. **Enable Auto-Sync**: For continuous deployment
4. **Set Resource Quotas**: Prevent resource exhaustion
5. **Monitor Drift**: Use ArgoCD dashboard to monitor configuration drift
6. **Use Helm Hooks**: For complex deployment scenarios

## Migration to Bitbucket

When migrating to Bitbucket:

1. Update repository URL in ArgoCD applications
2. Update any webhook configurations
3. Test access and permissions
4. Update documentation references
