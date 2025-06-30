#!/bin/bash
# validate-deployment.sh
# Script to validate Balance-fit GitOps manifests

echo "=== Balance-fit GitOps Deployment Validation ==="
echo "Date: $(date)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo
echo "1. Validating base configuration..."
kubectl kustomize base/ > /dev/null 2>&1
print_status "Base manifests validation"

echo
echo "2. Validating production overlay..."
kubectl kustomize overlays/production/ > /dev/null 2>&1
print_status "Production overlay validation"

echo
echo "3. Validating DR overlay..."
kubectl kustomize overlays/dr/ > /dev/null 2>&1
print_status "DR overlay validation"

echo
echo "4. Checking resource counts..."
PROD_RESOURCES=$(kubectl kustomize overlays/production/ | grep -c "^kind:")
DR_RESOURCES=$(kubectl kustomize overlays/dr/ | grep -c "^kind:")

echo "   Production resources: $PROD_RESOURCES"
echo "   DR resources: $DR_RESOURCES"

if [ "$PROD_RESOURCES" -eq "$DR_RESOURCES" ]; then
    print_status "Resource count consistency"
else
    print_warning "Resource count mismatch between production and DR"
fi

echo
echo "5. Checking for required components..."
REQUIRED_COMPONENTS=("Deployment" "Service" "ConfigMap" "Secret" "PersistentVolumeClaim" "Route" "Namespace")

for component in "${REQUIRED_COMPONENTS[@]}"; do
    if kubectl kustomize overlays/production/ | grep -q "kind: $component"; then
        print_status "$component present in production"
    else
        echo -e "${RED}❌ Missing $component in production${NC}"
    fi
done

echo
echo "6. Security checks..."
# Check for non-root containers
if kubectl kustomize overlays/production/ | grep -q "runAsNonRoot: true"; then
    print_status "Non-root security context configured"
else
    print_warning "Non-root security context not found"
fi

# Check for resource limits
if kubectl kustomize overlays/production/ | grep -q "limits:"; then
    print_status "Resource limits configured"
else
    print_warning "Resource limits not found"
fi

echo
echo "7. ArgoCD compatibility checks..."
if kubectl kustomize overlays/production/ | grep -q "app.kubernetes.io/managed-by: argocd"; then
    print_status "ArgoCD annotations present"
else
    print_warning "ArgoCD annotations not found"
fi

echo
echo "=== Validation Complete ==="
echo
echo "Next steps:"
echo "1. Create GitHub repository: kohler-apps/balance-fit-gitops"
echo "2. Push this repository to GitHub"
echo "3. Configure ArgoCD applications"
echo "4. Deploy to production cluster"
echo "5. Test and validate deployment"
echo "6. Set up DR cluster deployment"
echo
echo "For detailed instructions, see:"
echo "- GITHUB_SETUP.md"
echo "- docs/deployment-guide.md"
echo "- docs/argocd-setup.md"
