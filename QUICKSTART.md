# Quick Start Guide

## Installation

1. Clone or download this module to your project
2. Reference it in your Terraform configuration

## Basic Usage (No Collision Concerns)

```hcl
module "vault_app" {
  source = "./"
  
  app_name      = "my-app"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_token
}

output "namespace_path" {
  value = module.vault_app.namespace_path
}
```

Namespace created: `my-app`

---

## Preventing Name Collisions

### Option 1: With Organization UUID (Recommended)

```hcl
module "vault_app" {
  source = "./"
  
  app_name      = "my-app"
  app_id        = "550e8400-e29b-41d4-a716-446655440000"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_token
}
```

Namespace created: `550e8400-e29b-41d4-a716-446655440000/my-app`

### Option 2: With Random Suffix

```hcl
module "vault_app" {
  source = "./"
  
  app_name          = "my-app"
  use_random_suffix = true
  vault_address     = "https://vault.example.com:8200"
  vault_token       = var.vault_token
}
```

Namespace created: `my-app-a1b2c3d4` (random hex suffix)

### Option 3: With Prefix

```hcl
module "vault_app" {
  source = "./"
  
  app_name         = "my-app"
  namespace_prefix = "prod/team-a/"
  vault_address    = "https://vault.example.com:8200"
  vault_token      = var.vault_token
}
```

Namespace created: `prod/team-a/my-app`

### Option 4: Everything Combined (Best for Enterprise)

```hcl
module "vault_app" {
  source = "./"
  
  app_name         = "my-app"
  app_id           = var.customer_uuid
  namespace_prefix = "customers/"
  vault_address    = "https://vault.example.com:8200"
  vault_token      = var.vault_token
}
```

Namespace created: `customers/{customer_uuid}/my-app`

---

## Accessing Vault Credentials

```hcl
# Get the authentication configuration
output "app_auth" {
  value     = module.vault_app.app_auth_config
  sensitive = true
}

# Outputs:
# - namespace: The namespace path
# - role_id: For AppRole authentication
# - secret_id: For AppRole authentication (keep secure!)
# - vault_addr: The Vault address
```

---

## Waypoint Add-on Usage

### Simple Deployment

```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name      = context.application.name
    vault_address = var.vault_address
    vault_token   = var.vault_token
  }
}
```

### With UUID for Multi-Tenant

```bash
export VAULT_APP_ID="550e8400-e29b-41d4-a716-446655440000"
waypoint up
```

```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name      = context.application.name
    vault_address = var.vault_address
    vault_token   = var.vault_token
  }
  # app_id will be read from VAULT_APP_ID environment variable
}
```

### With Random Suffix

```bash
export VAULT_USE_RANDOM_SUFFIX="true"
waypoint up
```

---

## Environment Variables (Waypoint)

| Variable | Purpose | Example |
|----------|---------|---------|
| `VAULT_ADDR` | Vault server address | `https://vault.example.com:8200` |
| `VAULT_TOKEN` | Vault authentication token | Your admin token |
| `VAULT_NAMESPACE_PREFIX` | Namespace prefix | `prod/services/` |
| `VAULT_APP_ID` | Application UUID/ID | `550e8400...` |
| `VAULT_USE_RANDOM_SUFFIX` | Enable random suffix | `true` or `false` |

---

## Common Patterns

### Development Environment

```bash
export VAULT_USE_RANDOM_SUFFIX="true"
terraform apply
```

Each deploy gets a unique namespace for safety.

### Production (Multi-Customer)

```bash
export VAULT_APP_ID="${CUSTOMER_ID}"
export VAULT_NAMESPACE_PREFIX="prod/customers/"
terraform apply
```

Clear ownership and deterministic paths.

### Internal Services

```bash
# Store UUID in local state
terraform apply -var="app_id=service-auth-001"
```

Fixed, meaningful identifiers.

---

## Troubleshooting

### "Namespace already exists"
- Use different `app_id`
- Enable `use_random_suffix = true`
- Specify unique `namespace_path`

### "Provider error"
- Ensure Vault credentials are correct
- Check network access to Vault
- Verify Vault token has namespace creation permissions

### "Policy error"
- Check Vault token has policy management permissions
- Verify policy template file exists at `policies/app_policy.hcl`

### Need help?
See [COLLISION_AVOIDANCE.md](COLLISION_AVOIDANCE.md) for detailed strategies and [README.md](README.md) for full documentation.
