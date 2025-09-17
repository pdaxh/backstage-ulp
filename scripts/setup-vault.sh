#!/bin/bash

# Vault Setup Script for Backstage ULP
# This script helps you set up Vault with Backstage integration

set -e

echo "🔐 Setting up Vault for Backstage ULP..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker first."
  exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl is not installed. Please install kubectl first."
  exit 1
fi

# Function to start Vault with Docker Compose
start_vault_docker() {
  echo "🐳 Starting Vault with Docker Compose..."
  cd vault
  docker-compose -f docker-compose.vault.yml up -d
  
  echo "⏳ Waiting for Vault to be ready..."
  until curl -s http://localhost:8200/v1/sys/health >/dev/null 2>&1; do
    echo "Waiting for Vault..."
    sleep 2
  done
  
  echo "✅ Vault is ready at http://localhost:8200"
  echo "🔑 Root Token: dev-root-token"
  echo "🌐 Vault UI: http://localhost:8200/ui"
}

# Function to start Vault with Kubernetes
start_vault_k8s() {
  echo "☸️  Starting Vault with Kubernetes..."
  
  # Apply Vault deployment
  kubectl apply -f k8s/vault/vault-deployment.yaml
  
  echo "⏳ Waiting for Vault pod to be ready..."
  kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
  
  echo "✅ Vault is ready in Kubernetes"
  echo "🔑 Root Token: dev-root-token"
  
  # Port forward to access Vault
  echo "🌐 Port forwarding Vault to localhost:8200..."
  kubectl port-forward -n vault svc/vault 8200:8200 &
  VAULT_PID=$!
  echo "Vault port-forward PID: $VAULT_PID"
  echo "🌐 Vault UI: http://localhost:8200/ui"
}

# Function to initialize Vault
init_vault() {
  echo "🚀 Initializing Vault..."
  
  # Set Vault address
  export VAULT_ADDR="http://localhost:8200"
  export VAULT_TOKEN="dev-root-token"
  
  # Enable KV secrets engine
  echo "📦 Enabling KV secrets engine..."
  vault secrets enable -path=secret kv-v2 || true
  
  # Enable database secrets engine
  echo "🗄️  Enabling database secrets engine..."
  vault secrets enable database || true
  
  # Enable PKI secrets engine
  echo "🔐 Enabling PKI secrets engine..."
  vault secrets enable pki || true
  
  # Enable transit secrets engine
  echo "🔄 Enabling transit secrets engine..."
  vault secrets enable transit || true
  
  # Create policies
  echo "📋 Creating Vault policies..."
  
  # Backstage service policy
  vault policy write backstage-service - <<EOF
# Backstage service policy
path "secret/data/backstage/*" {
  capabilities = ["read"]
}

path "database/creds/backstage" {
  capabilities = ["read"]
}

path "transit/encrypt/backstage" {
  capabilities = ["update"]
}

path "transit/decrypt/backstage" {
  capabilities = ["update"]
}
EOF

  # ArgoCD policy
  vault policy write argocd - <<EOF
# ArgoCD policy
path "secret/data/argocd/*" {
  capabilities = ["read"]
}

path "secret/data/backstage/*" {
  capabilities = ["read"]
}
EOF

  # Create secrets
  echo "🔐 Creating secrets..."
  
  # Backstage secrets
  vault kv put secret/backstage/database \
    username="backstage" \
    password="backstage" \
    host="postgres" \
    port="5432" \
    database="backstage"
  
  vault kv put secret/backstage/auth \
    github_client_id="your_github_client_id" \
    github_client_secret="your_github_client_secret" \
    github_organization="your_org"
  
  vault kv put secret/backstage/app \
    backend_secret="dev-secret-please-change" \
    frontend_secret="frontend-secret" \
    session_secret="session-secret"
  
  # ArgoCD secrets
  vault kv put secret/argocd/github \
    token="your_github_token" \
    username="pdaxh"
  
  vault kv put secret/argocd/kubernetes \
    server="https://kubernetes.default.svc" \
    namespace="argocd"
  
  # Create service tokens
  echo "🎫 Creating service tokens..."
  
  # Backstage service token
  BACKSTAGE_TOKEN=$(vault token create -policy=backstage-service -format=json | jq -r '.auth.client_token')
  echo "Backstage Service Token: $BACKSTAGE_TOKEN"
  
  # ArgoCD service token
  ARGOCD_TOKEN=$(vault token create -policy=argocd -format=json | jq -r '.auth.client_token')
  echo "ArgoCD Service Token: $ARGOCD_TOKEN"
  
  # Save tokens
  cat > vault-tokens.txt <<EOF
# Vault Tokens for Backstage ULP
# Generated on $(date)

# Root Token (for admin operations)
ROOT_TOKEN=dev-root-token

# Service Tokens
BACKSTAGE_TOKEN=$BACKSTAGE_TOKEN
ARGOCD_TOKEN=$ARGOCD_TOKEN
EOF
  
  echo "✅ Vault initialization complete!"
  echo "📄 Tokens saved to vault-tokens.txt"
}

# Function to show Vault status
show_status() {
  echo "📊 Vault Status:"
  echo "================"
  
  if command -v vault &> /dev/null; then
    export VAULT_ADDR="http://localhost:8200"
    export VAULT_TOKEN="dev-root-token"
    vault status
  else
    echo "Vault CLI not found. Install it from https://www.vaultproject.io/downloads"
  fi
  
  echo ""
  echo "🔐 Available Secrets:"
  echo "===================="
  vault kv list secret/ || echo "No secrets found"
  
  echo ""
  echo "🌐 Access URLs:"
  echo "=============="
  echo "Vault UI: http://localhost:8200/ui"
  echo "Vault API: http://localhost:8200/v1/"
  echo "Root Token: dev-root-token"
}

# Main menu
case "${1:-menu}" in
  "docker")
    start_vault_docker
    init_vault
    show_status
    ;;
  "k8s")
    start_vault_k8s
    init_vault
    show_status
    ;;
  "init")
    init_vault
    show_status
    ;;
  "status")
    show_status
    ;;
  "menu"|*)
    echo "🔐 Vault Setup for Backstage ULP"
    echo "================================"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  docker  - Start Vault with Docker Compose"
    echo "  k8s     - Start Vault with Kubernetes"
    echo "  init    - Initialize Vault (secrets, policies, tokens)"
    echo "  status  - Show Vault status and available secrets"
    echo "  menu    - Show this menu"
    echo ""
    echo "Examples:"
    echo "  $0 docker    # Start Vault with Docker"
    echo "  $0 k8s       # Start Vault with Kubernetes"
    echo "  $0 init      # Initialize Vault"
    echo "  $0 status    # Check Vault status"
    ;;
esac
