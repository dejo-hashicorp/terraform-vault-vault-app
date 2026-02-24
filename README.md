# Terraform Vault Module

A Terraform module that creates isolated Vault namespaces for applications with built-in collision avoidance. Perfect for multi-tenant deployments and Waypoint add-ons.

## Features

- **Isolated Namespaces** - Each application gets its own namespace
- **AppRole Auth** - Automatic RoleID and SecretID generation
- **KV Secrets Engine** - V2 secrets storage within each namespace
- **Policy-Based Access** - Fine-grained permission control
- **Collision Avoidance** - Multiple strategies to handle duplicate app names:
  - **Organization/Team UUID** - Scope namespaces by customer/org (recommended for SaaS)
  - **Random Suffix** - Auto-append random ID
  - **Manual Override** - Full control over namespace path
- **Waypoint Integration** - Deploy as add-on to existing applications
- **Environment Variables** - Configure via env vars for CI/CD pipelines

## Quick Start

### Simple Deployment

```hcl
module "vault_app" {
  source = "./"

  app_name      = "payment-service"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_token
}

# Namespace created: payment-service
```

### Multi-Tenant with Organization UUID

```hcl
module "vault_app" {
  source = "./"

  app_name        = "payment-service"
  organization_id = "customer-uuid-123"
  vault_address   = "https://vault.example.com:8200"
  vault_token     = var.vault_token
}

# Namespace created: customer-uuid-123/payment-service
# Prevents collision if another customer also has "payment-service"
```

### With Prefix and Team Scoping

```hcl
module "vault_app" {
  source = "./"

  app_name         = "api-server"
  organization_id  = "acme-corp"
  team_id          = "platform-team"
  namespace_prefix = "production/"
  vault_address    = "https://vault.example.com:8200"
  vault_token      = var.vault_token
}

# Namespace created: production/acme-corp/platform-team/api-server
```

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vault_address` | string | Vault server address (e.g., `https://vault.example.com:8200`) |
| `vault_token` | string | Vault authentication token (sensitive) |
| `app_name` | string | Application name (1-50 chars) |

## Collision Avoidance Variables

| Variable | Type | Default | Description | Env Var |
|----------|------|---------|-------------|---------|
| `organization_id` | string | "" | Customer/organization UUID | `VAULT_ORGANIZATION_ID` |
| `team_id` | string | "" | Team ID for hierarchical scoping | `VAULT_TEAM_ID` |
| `app_id` | string | "" | Explicit app UUID (overrides organization_id) | `VAULT_APP_ID` |
| `use_random_suffix` | bool | false | Auto-append random suffix for uniqueness | `VAULT_USE_RANDOM_SUFFIX` |
| `namespace_prefix` | string | "" | Prefix for all namespaces (e.g., `production/`) | `VAULT_NAMESPACE_PREFIX` |
| `namespace_path` | string | "" | Manual namespace override (bypasses auto-generation) | - |

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vault_namespace` | string | "" | Parent Vault namespace to auth against |
| `skip_tls_verify` | bool | false | Skip TLS verification (not recommended for prod) |
| `secrets_engine_path` | string | "secrets" | KV engine mount path |
| `kv_path` | string | "data" | Data path within KV engine |
| `policy_name` | string | "app-policy" | Policy name |
| `auth_method_path` | string | "approle" | AppRole mount path |
| `role_name` | string | "app-role" | AppRole role name |
| `token_ttl` | number | 3600 | Token lifetime in seconds |
| `token_max_ttl` | number | 86400 | Max token lifetime in seconds |
| `secret_id_ttl` | number | 0 | SecretID lifetime (0 = never expires) |
| `bind_secret_id` | bool | true | Require SecretID for authentication |

## Outputs

| Output | Description |
|--------|-------------|
| `namespace_id` | Vault namespace ID |
| `namespace_path` | Full namespace path |
| `secrets_engine_path` | KV engine path |
| `policy_name` | Policy name |
| `role_id` | AppRole RoleID |
| `secret_id` | AppRole SecretID (sensitive) |
| `app_auth_config` | Complete auth config for application (sensitive) |
| `app_id` | Resolved app ID (UUID, org_id, or random) |
| `organization_id` | Organization ID if provided |
| `team_id` | Team ID if provided |

## Collision Avoidance Strategies

### Strategy 1: Organization/Team UUID (Recommended for SaaS)

Use organization and team identifiers to scope namespaces hierarchically.

```bash
export VAULT_ORGANIZATION_ID="customer-a-uuid"
export VAULT_TEAM_ID="payments-team"
terraform apply
```

**Result:** `{organization_id}/{team_id}/{app_name}`
**Best for:** Multi-tenant systems, clear ownership model

### Strategy 2: Random Suffix

Auto-generate a random suffix for uniqueness.

```hcl
module "vault_app" {
  source = "./"
  
  app_name          = "api-service"
  use_random_suffix = true
}
```

**Result:** `{app_name}-{random_hex}`
**Best for:** Simple deployments, no external UUID needed

### Strategy 3: Manual Override

Specify exact namespace path.

```hcl
module "vault_app" {
  source = "./"
  
  app_name       = "api-service"
  namespace_path = "production/team-a/v2"
}
```

**Best for:** Complex naming schemes, existing infrastructure

## Examples

### SaaS Multi-Tenant Setup

```hcl
locals {
  customers = {
    acme   = "acme-corp-uuid"
    beta   = "beta-industries-uuid"
  }
}

module "customer_vault" {
  for_each = local.customers
  
  source = "./"
  
  app_name        = "api-service"
  organization_id = each.value
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Creates:
# - acme-corp-uuid/api-service
# - beta-industries-uuid/api-service
```

### Enterprise Multi-Team

```hcl
variable "organization_id" {
  type = string
}

locals {
  teams = {
    platform   = "platform-team-uuid"
    payments   = "payments-team-uuid"
  }
}

module "team_services" {
  for_each = local.teams
  
  source = "./"
  
  app_name         = "service-a"
  organization_id  = var.organization_id
  team_id          = each.value
  namespace_prefix = "production/"
  vault_address    = var.vault_address
  vault_token      = var.vault_token
}

# Creates:
# - production/org/platform-team-uuid/service-a
# - production/org/payments-team-uuid/service-a
```

### CI/CD Pipeline

```bash
#!/bin/bash

case "${ENVIRONMENT}" in
  production)
    export VAULT_ORGANIZATION_ID="prod-org-uuid"
    export VAULT_NAMESPACE_PREFIX="prod/"
    ;;
  staging)
    export VAULT_ORGANIZATION_ID="staging-org-uuid"
    export VAULT_NAMESPACE_PREFIX="staging/"
    ;;
esac

terraform apply
```

## Waypoint Deployment

### Basic

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

### With Organization UUID

```bash
export VAULT_ORGANIZATION_ID="customer-uuid"
waypoint up
```

### With Team Scoping

```bash
export VAULT_ORGANIZATION_ID="acme-corp"
export VAULT_TEAM_ID="platform-team"
waypoint up
```

## Namespace Path Examples

```
# Simple (no collision avoidance)
api-service

# With organization
customer-uuid/api-service

# With organization + team
customer-uuid/payments-team/api-service

# With prefix
production/api-service

# Full hierarchy
production/customer-uuid/payments-team/api-service
```

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `VAULT_ADDR` | Vault address | `https://vault.example.com:8200` |
| `VAULT_TOKEN` | Vault token | Your admin token |
| `VAULT_NAMESPACE_PREFIX` | Namespace prefix | `production/` |
| `VAULT_ORGANIZATION_ID` | Organization UUID | `550e8400-e29b-41d4-...` |
| `VAULT_TEAM_ID` | Team ID | `payments-team` |
| `VAULT_APP_ID` | App UUID | `service-uuid` |
| `VAULT_USE_RANDOM_SUFFIX` | Enable random suffix | `true` |

## Application Usage

After deployment, use the credentials to access Vault:

```go
// Go example
import "github.com/hashicorp/vault-client-go"

client, _ := vault.New(
  vault.WithAddress(output.vault_addr),
  vault.WithAuthAppRole(roleID, secretID),
)

// Access secrets
secret, _ := client.Secrets.KvV2Read(
  context.Background(),
  "secret-name",
  vault.WithNamespace(output.namespace),
)
```

## Architecture

```
Vault Instance
└── Namespace (isolated for this application)
    ├── KV Secrets Engine (e.g., "secrets/")
    │   └── Application Secrets
    ├── AppRole Auth Method
    │   └── app-role
    │       ├── RoleID
    │       └── SecretID
    └── Policy (app-policy)
        └── Permissions for KV access
```

## Security

- **Sensitive Values** - All credentials marked sensitive in Terraform
- **Token TTL** - Set appropriate `token_ttl` and `token_max_ttl`
- **SecretID Binding** - Enable `bind_secret_id` (default true) to require both RoleID and SecretID
- **TLS** - Always use `skip_tls_verify = false` in production
- **Isolation** - Each namespace fully isolated; secrets cannot be shared between apps
- **Audit** - Enable Vault audit logging to track all access

## Troubleshooting

### "Namespace already exists"
- Use different `organization_id`, `team_id`, or `app_id`
- Enable `use_random_suffix = true` for automatic uniqueness

### "Permission denied"
- Verify Vault token has namespace creation permissions
- Check token has policy management capabilities

### "Wrong namespace structure"
Verify variables:
```bash
echo "Org: $VAULT_ORGANIZATION_ID"
echo "Team: $VAULT_TEAM_ID"
echo "App: $VAULT_APP_ID"
```

Priority order: `app_id` > `organization_id` > random suffix > default

### Debug Commands

```bash
# Check Terraform plan
terraform plan

# Verify namespace structure
vault namespace list
vault namespace read <namespace>
```

## Prerequisites

- Terraform >= 1.0
- Vault >= 1.8 with admin token
- Network access to Vault
- For Waypoint: Waypoint >= 1.0

## Module Files

```
.
├── main.tf              # Vault resources
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── waypoint.hcl        # Waypoint config
├── policies/
│   └── app_policy.hcl  # AppRole policy
└── README.md           # This file
```

## License

This module is provided as-is for use with HashiCorp Vault.
