#!/bin/bash

# Script to build and update Backstage image
set -e

# Configuration
IMAGE_NAME="ghcr.io/pdaxh/backstage-ulp"
TAG="${1:-latest}"
REGISTRY="ghcr.io"

echo "🚀 Building and updating Backstage image..."

# Build the image
echo "📦 Building Docker image..."
docker build -f backstage/packages/backend/Dockerfile -t ${IMAGE_NAME}:${TAG} ./backstage

# Tag as latest if not already
if [ "$TAG" != "latest" ]; then
    docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest
fi

# Login to registry (if needed)
echo "🔐 Logging in to GitHub Container Registry..."
echo "Please ensure you're logged in with: docker login ghcr.io"

# Push the image
echo "⬆️ Pushing image to registry..."
docker push ${IMAGE_NAME}:${TAG}
if [ "$TAG" != "latest" ]; then
    docker push ${IMAGE_NAME}:latest
fi

# Update Kubernetes manifests
echo "📝 Updating Kubernetes manifests..."
if [ "$TAG" != "latest" ]; then
    # Update with specific tag
    sed -i.bak "s|image: ghcr.io/pdaxh/backstage-ulp:latest|image: ${IMAGE_NAME}:${TAG}|g" k8s/base/backstage.yaml
    sed -i.bak "s|image: ghcr.io/pdaxh/backstage-ulp:latest|image: ${IMAGE_NAME}:${TAG}|g" k8s/overlays/production/backstage-production.yaml
    
    # Clean up backup files
    rm k8s/base/backstage.yaml.bak
    rm k8s/overlays/production/backstage-production.yaml.bak
fi

echo "✅ Image updated successfully!"
echo "🔄 ArgoCD should automatically detect the changes and sync the deployment."
echo "📊 Check your ArgoCD dashboard for deployment status."

# Optional: Commit changes
read -p "Do you want to commit and push the changes? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add k8s/
    git commit -m "Update Backstage image to ${TAG}"
    git push
    echo "📤 Changes committed and pushed!"
fi
