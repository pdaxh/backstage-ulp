# Vault Configuration for Backstage ULP
# This file contains the Vault server configuration

storage "file" {
  path = "/vault/data"
}

# Enable the KV secrets engine
secrets {
  path = "secret"
  description = "General secrets for Backstage ULP"
}

# Enable the database secrets engine for dynamic credentials
secrets {
  path = "database"
  description = "Database credentials for Backstage"
}

# Enable the PKI secrets engine for certificates
secrets {
  path = "pki"
  description = "PKI certificates for Backstage"
}

# Enable the transit secrets engine for encryption
secrets {
  path = "transit"
  description = "Transit encryption for Backstage"
}

# API listener
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true  # Disable TLS for development
}

# UI
ui = true

# Disable the mlock syscall (not recommended for production)
disable_mlock = true

# Log level
log_level = "INFO"

# Default lease TTL
default_lease_ttl = "1h"
max_lease_ttl = "24h"
