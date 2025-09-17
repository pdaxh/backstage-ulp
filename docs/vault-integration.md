# Vault Integration for Backstage ULP

This document describes how to integrate HashiCorp Vault with Backstage ULP for secure secret management.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backstage     │    │      Vault      │    │   Kubernetes    │
│   Frontend      │◄───┤   Secret Store  │◄───┤   Secrets       │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backstage     │    │   Vault Agent   │    │   ArgoCD        │
│   Backend       │◄───┤   Secret Inject │◄───┤   GitOps        │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Start Vault

Choose one of the following methods:

#### Option A: Docker Compose (Development)
```bash
# Start Vault with Docker
./scripts/setup-vault.sh docker
```

#### Option B: Kubernetes (Production)
```bash
# Start Vault with Kubernetes
./scripts/setup-vault.sh k8s
```

### 2. Initialize Vault
```bash
# Initialize Vault with secrets and policies
./scripts/setup-vault.sh init
```

### 3. Start Backstage with Vault
```bash
# Start Backstage with Vault configuration
cd backstage
yarn start --config app-config.vault.yaml
```

## 🔐 Secret Management

### Available Secrets

Vault stores the following secrets for Backstage:

#### Database Secrets
- **Path**: `secret/data/backstage/database`
- **Contents**:
  - `username`: Database username
  - `password`: Database password
  - `host`: Database host
  - `port`: Database port
  - `database`: Database name

#### Authentication Secrets
- **Path**: `secret/data/backstage/auth`
- **Contents**:
  - `github_client_id`: GitHub OAuth client ID
  - `github_client_secret`: GitHub OAuth client secret
  - `github_organization`: GitHub organization

#### Application Secrets
- **Path**: `secret/data/backstage/app`
- **Contents**:
  - `backend_secret`: Backend secret key
  - `frontend_secret`: Frontend secret key
  - `session_secret`: Session secret key

#### ArgoCD Secrets
- **Path**: `secret/data/argocd/github`
- **Contents**:
  - `token`: GitHub token for ArgoCD
  - `username`: GitHub username

### Managing Secrets

#### Using Vault CLI
```bash
# Set Vault environment
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="dev-root-token"

# Read a secret
vault kv get secret/backstage/database

# Write a secret
vault kv put secret/backstage/database \
  username="newuser" \
  password="newpass" \
  host="newhost" \
  port="5432" \
  database="newdb"

# List secrets
vault kv list secret/backstage/
```

#### Using Vault UI
1. Open http://localhost:8200/ui
2. Login with token: `dev-root-token`
3. Navigate to `secret/` to view and edit secrets

## 🔄 Secret Rotation

### Automatic Rotation
Vault can automatically rotate secrets using the database secrets engine:

```bash
# Configure database secrets engine
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/backstage" \
  allowed_roles="backstage" \
  username="backstage" \
  password="backstage"

# Create a role for automatic rotation
vault write database/roles/backstage \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"
```

### Manual Rotation
```bash
# Rotate a specific secret
vault kv put secret/backstage/database \
  username="newuser" \
  password="newpass"

# Restart Backstage to pick up new secrets
kubectl rollout restart deployment/backstage -n backstage
```

## 🔒 Security Best Practices

### 1. Token Management
- Use short-lived tokens for services
- Rotate tokens regularly
- Use different policies for different services

### 2. Secret Policies
- Follow principle of least privilege
- Use specific paths in policies
- Regularly audit access

### 3. Encryption
- Use Vault's transit engine for encryption
- Encrypt sensitive data at rest
- Use TLS for Vault communication

### 4. Monitoring
- Enable audit logging
- Monitor secret access
- Set up alerts for failed access

## 🛠️ Troubleshooting

### Common Issues

#### 1. Vault Connection Failed
```bash
# Check Vault status
vault status

# Check Vault logs
docker logs vault
# or
kubectl logs -n vault deployment/vault
```

#### 2. Secret Not Found
```bash
# Check if secret exists
vault kv get secret/backstage/database

# Check policy permissions
vault policy read backstage-service
```

#### 3. Token Expired
```bash
# Check token status
vault token lookup

# Renew token
vault token renew
```

### Debug Commands

```bash
# Check Vault health
curl http://localhost:8200/v1/sys/health

# List all secrets
vault kv list secret/

# Check policies
vault policy list

# Check tokens
vault token list
```

## 📚 API Reference

### Vault API Endpoints

#### Health Check
```bash
GET /v1/sys/health
```

#### Read Secret
```bash
GET /v1/secret/data/{path}
```

#### Write Secret
```bash
PUT /v1/secret/data/{path}
```

#### List Secrets
```bash
GET /v1/secret/metadata/{path}?list=true
```

### Backstage Vault Plugin

The Backstage Vault plugin provides the following endpoints:

#### Health Check
```bash
GET /api/vault/health
```

#### Get Secret
```bash
GET /api/vault/secrets/{path}
```

#### List Secrets
```bash
GET /api/vault/secrets
```

#### Encrypt Data
```bash
POST /api/vault/encrypt
{
  "data": "sensitive data",
  "keyName": "backstage-key"
}
```

#### Decrypt Data
```bash
POST /api/vault/decrypt
{
  "data": "encrypted data",
  "keyName": "backstage-key"
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault server address | `http://localhost:8200` |
| `VAULT_TOKEN` | Vault authentication token | `dev-root-token` |
| `VAULT_NAMESPACE` | Vault namespace | (empty) |

### Backstage Configuration

```yaml
# app-config.vault.yaml
vault:
  addr: ${VAULT_ADDR}
  token: ${VAULT_TOKEN}

database:
  connection:
    host: ${PGHOST}
    port: ${PGPORT}
    user: ${PGUSER}
    password: ${PGPASSWORD}
    database: ${PGDATABASE}
```

## 🚀 Production Deployment

### 1. High Availability
- Deploy Vault in HA mode
- Use Consul or etcd for storage
- Enable auto-unseal

### 2. Security
- Enable TLS
- Use proper authentication methods
- Implement network policies

### 3. Monitoring
- Enable audit logging
- Set up metrics collection
- Configure alerting

### 4. Backup
- Regular backup of Vault data
- Test restore procedures
- Document recovery process

## 📖 Additional Resources

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Best Practices](https://www.vaultproject.io/docs/best-practices)
- [Backstage Documentation](https://backstage.io/docs)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
