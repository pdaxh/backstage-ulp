#!/bin/bash

# Vault Initialization Script for Backstage ULP
# This script sets up Vault with the necessary secrets and policies

set -e

echo "🔐 Initializing Vault for Backstage ULP..."

# Wait for Vault to be ready
echo "⏳ Waiting for Vault to be ready..."
until vault status >/dev/null 2>&1; do
  echo "Waiting for Vault..."
  sleep 2
done

echo "✅ Vault is ready!"

# Check if Vault is already initialized
if vault status | grep -q "Initialized.*true"; then
  echo "⚠️  Vault is already initialized. Skipping initialization."
  exit 0
fi

# Initialize Vault
echo "🚀 Initializing Vault..."
vault operator init -key-shares=1 -key-threshold=1 > vault-init.txt

# Extract unseal key and root token
UNSEAL_KEY=$(grep "Unseal Key 1:" vault-init.txt | awk '{print $4}')
ROOT_TOKEN=$(grep "Initial Root Token:" vault-init.txt | awk '{print $4}')

echo "🔑 Unseal Key: $UNSEAL_KEY"
echo "🎫 Root Token: $ROOT_TOKEN"

# Unseal Vault
echo "🔓 Unsealing Vault..."
vault operator unseal $UNSEAL_KEY

# Set environment variable for subsequent commands
export VAULT_TOKEN=$ROOT_TOKEN

# Enable KV secrets engine
echo "📦 Enabling KV secrets engine..."
vault secrets enable -path=secret kv-v2

# Enable database secrets engine
echo "🗄️  Enabling database secrets engine..."
vault secrets enable database

# Enable PKI secrets engine
echo "🔐 Enabling PKI secrets engine..."
vault secrets enable pki

# Enable transit secrets engine
echo "🔄 Enabling transit secrets engine..."
vault secrets enable transit

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

# Admin policy
vault policy write admin - <<EOF
# Admin policy
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
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

# Create tokens
echo "🎫 Creating service tokens..."

# Backstage service token
BACKSTAGE_TOKEN=$(vault token create -policy=backstage-service -format=json | jq -r '.auth.client_token')
echo "Backstage Service Token: $BACKSTAGE_TOKEN"

# ArgoCD service token
ARGOCD_TOKEN=$(vault token create -policy=argocd -format=json | jq -r '.auth.client_token')
echo "ArgoCD Service Token: $ARGOCD_TOKEN"

# Save tokens to file
echo "💾 Saving tokens to vault-tokens.txt..."
cat > vault-tokens.txt <<EOF
# Vault Tokens for Backstage ULP
# Generated on $(date)

# Root Token (for admin operations)
ROOT_TOKEN=$ROOT_TOKEN

# Service Tokens
BACKSTAGE_TOKEN=$BACKSTAGE_TOKEN
ARGOCD_TOKEN=$ARGOCD_TOKEN

# Unseal Key
UNSEAL_KEY=$UNSEAL_KEY
EOF

echo "✅ Vault initialization complete!"
echo "📄 Tokens saved to vault-tokens.txt"
echo "🔑 Unseal Key: $UNSEAL_KEY"
echo "🎫 Root Token: $ROOT_TOKEN"
echo ""
echo "⚠️  IMPORTANT: Save these credentials securely!"
echo "   - Unseal Key: $UNSEAL_KEY"
echo "   - Root Token: $ROOT_TOKEN"
echo ""
echo "🚀 Vault is ready for Backstage ULP!"
