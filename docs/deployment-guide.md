# Balance-fit Deployment Guide

This guide explains how to deploy the Balance-fit application using GitOps methodology with ArgoCD and Kustomize.

## Prerequisites

- OpenShift cluster with ArgoCD installed
- Access to the Kohler container registries
- `kubectl` or `oc` CLI tools
- `kustomize` CLI tool (optional)

## Deployment Steps

### 1. Production Deployment

#### Via kubectl/oc CLI:
```bash
# Clone the repository
git clone https://github.com/kohler-apps/balance-fit-gitops.git
cd balance-fit-gitops

# Preview the production configuration
kubectl kustomize overlays/production/

# Deploy to production
kubectl apply -k overlays/production/

# Verify deployment
kubectl get pods -n balance-fit-prd
kubectl get routes -n balance-fit-prd
```

#### Via ArgoCD:
```bash
# Create ArgoCD application for production
argocd app create balance-fit-prod \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace balance-fit-prd \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Sync the application
argocd app sync balance-fit-prod
```

### 2. DR Deployment

#### Via kubectl/oc CLI:
```bash
# Deploy to DR cluster
kubectl apply -k overlays/dr/ --context=dr-cluster

# Verify deployment
kubectl get pods -n balance-fit-dr --context=dr-cluster
```

#### Via ArgoCD:
```bash
# Create ArgoCD application for DR
argocd app create balance-fit-dr \
  --repo https://github.com/kohler-apps/balance-fit-gitops \
  --path overlays/dr \
  --dest-server https://ocp-dr.kohlerco.com:6443 \
  --dest-namespace balance-fit-dr \
  --sync-policy automated

# Sync the DR application
argocd app sync balance-fit-dr
```

## Configuration Management

### Environment-Specific Configurations

#### Production (`overlays/production/`)
- **Replicas**: 2 for nginx and efit (high availability)
- **Resources**: Higher CPU/memory limits
- **Storage**: 20GB app data, 50GB MySQL data
- **Route**: balance-fit.apps.ocp-prd.kohlerco.com

#### DR (`overlays/dr/`)
- **Replicas**: 1 for all components (cost optimization)
- **Resources**: Standard limits
- **Storage**: 10GB app data, 20GB MySQL data
- **Route**: balance-fit.apps.ocp-dr.kohlerco.com

### Secrets Management

Currently, secrets are stored as plaintext in the repository for initial setup. For production use, implement one of these solutions:

#### Option 1: Sealed Secrets
```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Create sealed secret
echo -n "password123" | kubectl create secret generic mysql-secret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal -o yaml > mysql-sealed-secret.yaml
```

#### Option 2: External Secrets Operator
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.kohlerco.com"
      path: "secret"
      version: "v2"
```

## Monitoring and Health Checks

### Application Health
```bash
# Check all components
kubectl get pods,svc,routes -n balance-fit-prd

# Check nginx logs
kubectl logs deployment/nginx -n balance-fit-prd

# Check PHP application logs
kubectl logs deployment/efit -n balance-fit-prd

# Check MySQL logs
kubectl logs deployment/mysql -n balance-fit-prd

# Test application endpoint
kubectl exec -n balance-fit-prd deployment/nginx -- curl -I http://localhost:8030
```

### ArgoCD Monitoring
```bash
# Check application status
argocd app get balance-fit-prod

# View application logs
argocd app logs balance-fit-prod

# Check sync status
argocd app list
```

## Scaling Operations

### Manual Scaling
```bash
# Scale nginx replicas
kubectl scale deployment nginx --replicas=3 -n balance-fit-prd

# Scale PHP application
kubectl scale deployment efit --replicas=3 -n balance-fit-prd
```

### GitOps Scaling
1. Update the replica count in the appropriate kustomization file
2. Commit and push changes
3. ArgoCD will automatically sync the changes

## Troubleshooting

### Common Issues

#### 1. ImagePullBackOff
```bash
# Check if registry is whitelisted
oc get image.config.openshift.io/cluster -o yaml | grep allowedRegistries

# Check image pull secrets
kubectl get secrets -n balance-fit-prd | grep docker
```

#### 2. Application Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n balance-fit-prd

# Check resource constraints
kubectl top pods -n balance-fit-prd
kubectl describe node
```

#### 3. Database Connection Issues
```bash
# Test MySQL connectivity
kubectl exec -it deployment/mysql -n balance-fit-prd -- mysql -u efit -p

# Check MySQL service
kubectl get svc mysql-service -n balance-fit-prd
```

## Backup and Recovery

### Database Backup
```bash
# Create MySQL backup
kubectl exec deployment/mysql -n balance-fit-prd -- mysqldump -u root -p efit > backup.sql

# Restore from backup
kubectl exec -i deployment/mysql -n balance-fit-prd -- mysql -u root -p efit < backup.sql
```

### Application Data Backup
```bash
# Backup application files
kubectl exec deployment/nginx -n balance-fit-prd -- tar -czf /tmp/app-backup.tar.gz /code

# Copy backup to local
kubectl cp balance-fit-prd/nginx-pod:/tmp/app-backup.tar.gz ./app-backup.tar.gz
```

## Security Considerations

1. **Secrets**: Migrate to sealed-secrets or external-secrets
2. **Registry**: Ensure private registries are properly secured
3. **Network Policies**: Implement network segmentation
4. **RBAC**: Set up proper role-based access control
5. **Security Context**: All containers run as non-root users

## Migration Checklist

- [ ] Deploy to production environment
- [ ] Verify application functionality
- [ ] Set up monitoring and alerting
- [ ] Configure backup procedures
- [ ] Test DR deployment
- [ ] Document operational procedures
- [ ] Migrate repository to Bitbucket
- [ ] Set up production secrets management
