# Backstage-ULP

A Backstage Developer Portal for ULP, deployed via Helm and managed by ArgoCD.

## 🏗️ Architecture

This project consists of:

- **`backstage/`** - The actual Backstage application source code
- **`helm/backstage/`** - Helm chart for Kubernetes deployment
- **`argocd/`** - ArgoCD application configuration
- **`.github/workflows/`** - CI/CD pipelines for building and deploying

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- Docker and Docker Buildx
- Helm 3.x
- kubectl configured

### 🚀 **Complete Deployment Commands**

#### **1. Initial Setup (One-time)**
```bash
# Clone the repository
git clone https://github.com/pdaxh/backstage-ulp.git
cd backstage-ULP

# Build the Backstage application
cd backstage
yarn install --immutable
yarn build:backend
cd ..

# Build Docker image
docker build -f backstage/packages/backend/Dockerfile -t ghcr.io/pdaxh/backstage-ulp:dev ./backstage

# Push to registry
docker push ghcr.io/pdaxh/backstage-ulp:dev
```

#### **2. Deploy with Helm (Local)**
```bash
# Create namespace and deploy
kubectl create namespace backstage
helm upgrade --install backstage ./helm/backstage -n backstage --create-namespace

# Check deployment status
kubectl get pods -n backstage
helm status backstage -n backstage
```

#### **3. Deploy with ArgoCD**
```bash
# Apply ArgoCD application
kubectl apply -f argocd/application-backstage.yaml

# Check ArgoCD sync status
kubectl get applications -n argocd
argocd app sync backstage
```

#### **4. Testing & Verification**
```bash
# Test Backstage locally
kubectl port-forward svc/backstage -n backstage 7007:80
# Access at: http://localhost:7007

# Check logs
kubectl logs -f deployment/backstage -n backstage
```

#### **5. Update & Redeploy**
```bash
# When you make changes to Backstage
cd backstage
yarn build:backend
cd ..
docker build -f backstage/packages/backend/Dockerfile -t ghcr.io/pdaxh/backstage-ulp:dev ./backstage
docker push ghcr.io/pdaxh/backstage-ulp:dev

# ArgoCD will automatically detect and deploy changes
```

### Local Development

1. **Navigate to the Backstage app:**
   ```bash
   cd backstage
   ```

2. **Install dependencies:**
   ```bash
   yarn install
   ```

3. **Start the development server:**
   ```bash
   yarn dev
   ```

4. **Access Backstage at:** http://localhost:3000

### Building Docker Image

1. **Build the image:**
   ```bash
   docker build -t ghcr.io/danielaxhammar/backstage:dev ./backstage
   ```

2. **Push to registry:**
   ```bash
   docker push ghcr.io/danielaxhammar/backstage:dev
   ```

### Deploying with Helm

1. **Install/upgrade the chart:**
   ```bash
   # Development
   helm upgrade --install backstage ./helm/backstage -n backstage -f helm/backstage/values-dev.yaml
   
   # Production
   helm upgrade --install backstage ./helm/backstage -n backstage -f helm/backstage/values-prod.yaml
   ```

2. **Check deployment status:**
   ```bash
   kubectl get pods -n backstage
   helm status backstage -n backstage
   ```

### Deploying with ArgoCD

1. **Apply the ArgoCD application:**
   ```bash
   kubectl apply -f argocd/application-backstage.yaml
   ```

2. **Monitor sync status:**
   ```bash
   kubectl get applications -n argocd
   argocd app sync backstage
   ```

## 📁 Project Structure

```
Backstage-ULP/
├── backstage/                    # Backstage app source (working app)
│   ├── packages/
│   │   ├── app/                 # Frontend application
│   │   └── backend/             # Backend services
│   ├── package.json
│   └── app-config.yaml
├── helm/backstage/              # Helm chart
│   ├── templates/               # Kubernetes manifests
│   ├── values.yaml              # Default values
│   ├── values-dev.yaml          # Development overrides
│   └── values-prod.yaml         # Production overrides
├── argocd/                      # ArgoCD configuration
│   └── application-backstage.yaml
├── .github/workflows/           # CI/CD pipelines
│   └── build-push.yaml
└── README.md
```

## ⚙️ Configuration

### Helm Values

- **`values.yaml`** - Base configuration
- **`values-dev.yaml`** - Development environment overrides
- **`values-prod.yaml`** - Production environment overrides

### Environment Variables

Key environment variables can be set in the Helm values:

```yaml
env:
  NODE_ENV: production
  BACKEND_URL: https://backstage.ulp.com
  POSTGRES_HOST: postgres-service
  POSTGRES_PORT: "5432"
```

### Ingress Configuration

Configure external access via the ingress settings:

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: backstage.ulp.com
      paths:
        - path: /
          pathType: Prefix
```

## 🔧 Customization

### Adding Plugins

1. **Install plugin packages:**
   ```bash
   cd backstage
   yarn add @backstage/plugin-techdocs
   ```

2. **Configure in `app-config.yaml`:**
   ```yaml
   plugins:
     techdocs:
       enabled: true
   ```

3. **Rebuild and redeploy:**
   ```bash
   docker build -t ghcr.io/danielaxhammar/backstage:dev ./backstage
   docker push ghcr.io/danielaxhammar/backstage:dev
   ```

### Custom Pages

Create new pages in `backstage/packages/app/src/components/` and register them in the app.

## 🚀 CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Builds** Docker images on push to main/develop
2. **Tests** the application on pull requests
3. **Pushes** images to GitHub Container Registry
4. **Deploys** to development environment (develop branch)

### Manual Deployment

```bash
# Build and push
docker build -t ghcr.io/danielaxhammar/backstage:latest ./backstage
docker push ghcr.io/danielaxhammar/backstage:latest

# Deploy with Helm
helm upgrade --install backstage ./helm/backstage -n backstage -f helm/backstage/values-prod.yaml
```

## 📊 Monitoring & Health Checks

### Health Endpoints

- **Liveness Probe:** `/healthz` (every 10s)
- **Readiness Probe:** `/healthz` (every 5s)

### Resource Monitoring

```bash
# Check pod status
kubectl get pods -n backstage

# Check resource usage
kubectl top pods -n backstage

# View logs
kubectl logs -f deployment/backstage -n backstage
```

## 🔒 Security

### RBAC

The Helm chart creates:
- ServiceAccount with appropriate permissions
- Role and RoleBinding for Kubernetes resources
- Security contexts for pods and containers

### Secrets Management

Use Kubernetes secrets or external secret operators for sensitive data:

```yaml
secret:
  POSTGRES_PASSWORD: "base64-encoded-password"
  GITHUB_TOKEN: "base64-encoded-token"
```

## 🐛 Troubleshooting

### Common Issues

1. **Image Pull Errors:**
   - Verify image repository and tags
   - Check registry authentication

2. **Pod Startup Issues:**
   - Check resource limits
   - Verify configuration files
   - Review startup logs

3. **Ingress Issues:**
   - Verify ingress controller is running
   - Check hostname resolution
   - Verify TLS certificates

### Debug Commands

```bash
# Check Helm release status
helm status backstage -n backstage

# Validate Helm chart
helm lint ./helm/backstage

# Dry run deployment
helm install --dry-run --debug backstage ./helm/backstage -n backstage

# Check ArgoCD sync
argocd app get backstage
```

## 📚 Additional Resources

- [Backstage Documentation](https://backstage.io/docs)
- [Helm Documentation](https://helm.sh/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io)
- [Kubernetes Documentation](https://kubernetes.io/docs)

## 🚀 **Quick Reference - Essential Commands**

```bash
# 1. Deploy ArgoCD first (from argocd-ULP repo)
helm upgrade --install argocd-ulp ./argocd-ULP --namespace argocd --create-namespace --wait

# 2. Deploy Backstage via ArgoCD
kubectl apply -f backstage-ULP/argocd/application-backstage.yaml

# 3. Check status
kubectl get pods -n backstage
kubectl get applications -n argocd

# 4. Access Backstage
kubectl port-forward svc/backstage -n backstage 7007:80
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and with CI
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
