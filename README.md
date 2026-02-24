# Terraform Vault No-Code Module

A Terraform no-code module that creates isolated Vault namespaces for applications. This module enables applications to have their own dedicated secret storage and authentication mechanisms within an existing Vault instance. Designed to be deployed as a Waypoint add-on.

## Overview

This module provisions:
- **Vault Namespace**: An isolated namespace for the application
- **KV Secrets Engine**: A KV v2 secrets engine within the namespace
- **AppRole Authentication**: An AppRole auth method for secure application authentication
- **Policy**: A policy defining access permissions for the application
- **Secret Management**: Automated generation of RoleID and SecretID for application access
- **Collision Avoidance**: Multiple strategies to ensure unique namespaces even when app names collide

## Features

- 🔐 Isolated secret storage per application
- 🎯 AppRole authentication for secure service-to-service communication
- ⚙️ No-code deployment via Waypoint add-ons
- 🔑 Automatic credential generation
- 🛡️ Policy-based access control
- 📝 Configurable TTLs and security settings
- 🆔 UUID/ID-based collision avoidance for duplicate app names
- 🎲 Optional random suffix for automatic uniqueness

## Prerequisites

- Terraform >= 1.0
- Vault >= 1.8 with admin access
- Valid Vault token with appropriate permissions
- Waypoint >= 1.0 (for add-on deployment)

## Usage

### Direct Terraform Usage - Simple (Recommended)

```hcl
module "vault_app_namespace" {
  source = "./"

  app_name      = "my-application"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
  # namespace_path will be auto-generated as: my-application
}
```

### Direct Terraform Usage - With Prefix

```hcl
module "vault_app_namespace" {
  source = "./"

  app_name           = "my-application"
  vault_address      = "https://vault.example.com:8200"
  vault_token        = var.vault_admin_token
  namespace_prefix   = "ns1/cns2/"
  # namespace_path will be auto-generated as: ns1/cns2/my-application
}
```

### Via Waypoint Add-on - Simple

```hcl
addon {
  pack = "terraform-vault-vault-app"

  variables = {
    app_name           = "my-application"
    vault_address      = "https://vault.example.com:8200"
    vault_token        = var.vault_token
  }
}
```

### Via Waypoint Add-on - With Environment Variable Prefix

Set the environment variable before running Waypoint:
```bash
export VAULT_NAMESPACE_PREFIX="ns1/cns2/"
waypoint up
```

Then in your Waypoint configuration (the prefix will be automatically picked up):
```hcl
addon {
  pack = "terraform-vault-vault-app"

  variables = {
    app_name           = "my-application"
    vault_address      = "https://vault.example.com:8200"
    vault_token        = var.vault_token
    # namespace_prefix will be read from VAULT_NAMESPACE_PREFIX env var
  }
}
```

## Module Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vault_address` | string | The address of the Vault instance (e.g., https://vault.example.com:8200) |
| `vault_token` | string | The authentication token for Vault (sensitive) |
| `app_name` | string | The name of the application (1-50 characters) - namespace is derived from this |

### Collision Avoidance Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `app_id` | string | "" | A unique identifier (UUID, organization ID, team ID) to prevent namespace collisions. Creates namespace path: `{prefix}/{app_id}/{app_name}`. Set via `VAULT_APP_ID` env var in Waypoint |
| `organization_id` | string | "" | Organization or customer UUID. Fallback if `app_id` not provided. Set via `VAULT_ORGANIZATION_ID` env var |
| `team_id` | string | "" | Team ID for additional namespace scoping. When both `organization_id` and `team_id` provided, creates: `{prefix}/{organization_id}/{team_id}/{app_id}/{app_name}`. Set via `VAULT_TEAM_ID` env var |
| `use_random_suffix` | bool | false | Generates a random 4-byte hex suffix appended to namespace. Creates path: `{prefix}{app_name}-{random}`. Ignored if `app_id` or `organization_id` is provided. Set via `VAULT_USE_RANDOM_SUFFIX` env var |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `namespace_prefix` | string | "" | The prefix path for the Vault namespace (e.g., 'ns1/cns2/'). Can be set via `VAULT_NAMESPACE_PREFIX` environment variable |
| `namespace_path` | string | "" | Override for the complete namespace path. If provided, ignores all other path construction logic |
| `vault_namespace` | string | "" | The parent Vault namespace to authenticate to |
| `skip_tls_verify` | bool | false | Skip TLS verification when connecting to Vault |
| `secrets_engine_path` | string | "secrets" | The path where the KV secrets engine will be mounted |
| `kv_path` | string | "data" | The path within the KV engine where secrets are stored |
| `policy_name` | string | "app-policy" | The name of the policy to create |
| `auth_method_path` | string | "approle" | The path where AppRole auth method will be mounted |
| `role_name` | string | "app-role" | The name of the AppRole role |
| `token_ttl` | number | 3600 | The TTL of issued tokens in seconds (1 hour) |
| `token_max_ttl` | number | 86400 | The max TTL of issued tokens in seconds (24 hours) |
| `secret_id_ttl` | number | 0 | The TTL of the SecretID in seconds (0 = no expiration) |
| `bind_secret_id` | bool | true | Whether the role should require a SecretID |

## Module Outputs

| Output | Description |
|--------|-------------|
| `namespace_id` | The ID of the created Vault namespace |
| `namespace_path` | The path of the created Vault namespace |
| `secrets_engine_path` | The path of the KV secrets engine |
| `policy_name` | The name of the created policy |
| `auth_method_path` | The path of the AppRole auth method |
| `role_name` | The name of the AppRole role |
| `role_id` | The RoleID for AppRole authentication |
| `secret_id` | The SecretID for AppRole authentication (sensitive) |
| `app_auth_config` | Complete AppRole configuration object for the application (sensitive) |

## Example Configuration

### Basic Example (App name becomes namespace)

```hcl
module "app_vault" {
  source = "./"

  app_name      = "payment-service"
  vault_address = "https://vault.internal.company.com:8200"
  vault_token   = var.vault_admin_token
  # Namespace will be: payment-service
}

output "app_credentials" {
  value     = module.app_vault.app_auth_config
  sensitive = true
}
```

### With Organization UUID (Recommended for Multi-Tenant)

```hcl
module "app_vault" {
  source = "./"

  app_name        = "app-a"
  organization_id = "550e8400-e29b-41d4-a716-446655440000"  # Customer/Org UUID
  vault_address   = "https://vault.internal.company.com:8200"
  vault_token     = var.vault_admin_token
  # Namespace will be: 550e8400-e29b-41d4-a716-446655440000/app-a
  # This prevents collision even if another customer also has "app-a"
}
```

### With Organization + Team UUID (Hierarchical)

```hcl
module "app_vault" {
  source = "./"

  app_name        = "payment-service"
  organization_id = "acme-corp-uuid"
  team_id         = "payments-team-uuid"
  vault_address   = "https://vault.internal.company.com:8200"
  vault_token     = var.vault_admin_token
  # Namespace will be: acme-corp-uuid/payments-team-uuid/payment-service
}
```

### With Organization UUID via Environment Variable

```bash
# Set environment variable with organization UUID
export VAULT_ORGANIZATION_ID="550e8400-e29b-41d4-a716-446655440000"
terraform apply
```

```hcl
module "app_vault" {
  source = "./"

  app_name      = "app-a"
  vault_address = "https://vault.internal.company.com:8200"
  vault_token   = var.vault_admin_token
  # organization_id read from VAULT_ORGANIZATION_ID env var
  # Namespace will be: 550e8400-e29b-41d4-a716-446655440000/app-a
}
```

### With Auto-Generated UUID

```hcl
module "app_vault" {
  source = "./"

  app_name      = "my-service"
  app_id        = uuidv4()  # Generates unique UUID
  vault_address = "https://vault.internal.company.com:8200"
  vault_token   = var.vault_admin_token
  # Namespace will be: <generated-uuid>/my-service
}
```

### With Random Suffix (Simple Alternative)

```hcl
module "app_vault" {
  source = "./"

  app_name           = "app-b"
  use_random_suffix  = true
  vault_address      = "https://vault.internal.company.com:8200"
  vault_token        = var.vault_admin_token
  # Namespace will be: app-b-a1b2c3d4 (with random suffix)
}
```

### With Namespace Prefix

```hcl
module "app_vault" {
  source = "./"

  app_name           = "payment-service"
  vault_address      = "https://vault.internal.company.com:8200"
  vault_token        = var.vault_admin_token
  namespace_prefix   = "production/services/"
  # Namespace will be: production/services/payment-service
}
```

### With Prefix + UUID (Best Practice)

```hcl
module "app_vault" {
  source = "./"

  app_name        = "payment-service"
  organization_id = var.customer_uuid
  vault_address   = "https://vault.internal.company.com:8200"
  vault_token     = var.vault_admin_token
  namespace_prefix = "production/"
  # Namespace will be: production/{customer_uuid}/payment-service
}
```

### With Prefix + Organization + Team (Enterprise Multi-Tier)

```hcl
module "app_vault" {
  source = "./"

  app_name         = "api-gateway"
  organization_id  = var.customer_id
  team_id          = var.team_id
  vault_address    = "https://vault.internal.company.com:8200"
  vault_token      = var.vault_admin_token
  namespace_prefix = "production/customers/"
  # Namespace will be: production/customers/{customer_id}/{team_id}/api-gateway
}
```

### With Custom Settings

```hcl
module "app_vault" {
  source = "./"

  app_name            = "database-migrate"
  app_id              = "team-data-eng"
  vault_address       = "https://vault.internal.company.com:8200"
  vault_token         = var.vault_admin_token
  namespace_prefix    = "staging/"
  policy_name         = "db-migrate-policy"
  secrets_engine_path = "db-secrets"
  token_ttl           = 1800  # 30 minutes
  token_max_ttl       = 43200 # 12 hours
  # Namespace will be: staging/team-data-eng/database-migrate
}
```

## Generating UUIDs

When using the `app_id` variable, you can generate UUIDs in several ways:

### Using `uuidv4()` in Terraform

```hcl
module "app_vault" {
  source = "./"

  app_name      = "app-a"
  app_id        = uuidv4()  # Generates random UUID on each apply
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
}
```

### Using External UUID Tools

```bash
# Generate UUID once, then use it
export VAULT_APP_ID=$(uuidgen)
terraform apply
```

### Using Organization/Team Identifiers

```hcl
module "app_vault" {
  source = "./"

  app_name      = "app-a"
  app_id        = "${var.organization_id}-${var.team_id}"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
}
```

### Recommendation: Store and Reuse IDs

For production environments, store the `app_id` in state or configuration to ensure consistency:

```hcl
locals {
  app_id = "org-prod-payment-service"  # Fixed identifier
}

module "app_vault" {
  source = "./"

  app_name      = "payment-service"
  app_id        = local.app_id
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
}

output "namespace_details" {
  value = {
    app_id = local.app_id
    path   = module.app_vault.namespace_path
  }
}
```

## Access Control

The created policy grants the application the following capabilities:

- **Read/Write/Delete secrets**: Full access to secrets within the KV engine
- **List secrets**: Ability to list available secrets
- **Renew tokens**: Ability to renew authentication tokens

## Authentication Flow

1. Application authenticates using RoleID and SecretID
2. Vault returns a token valid for the specified TTL
3. Application uses token to access secrets in its namespace
4. Application renews token before expiration

## Security Considerations

- Store the SecretID securely (consider using Vault's Secret ID rotation)
- Rotate credentials regularly
- Use `token_ttl` and `token_max_ttl` to limit token validity
- The module enforces SecretID requirements by default (`bind_secret_id = true`)
- Use appropriate TLS verification in production (`skip_tls_verify = false`)

## Module Structure

```
.
├── main.tf           # Main configuration with Vault resources
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── waypoint.hcl      # Waypoint add-on configuration
├── policies/
│   └── app_policy.hcl # AppRole policy template
└── README.md         # This file
```

## Waypoint Deployment

To deploy as a Waypoint add-on in your application:

### Simple Deployment (App name as namespace)

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

### With Organization UUID (Recommended)

```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name        = context.application.name
    organization_id = var.customer_uuid  # Use customer/org UUID
    vault_address   = var.vault_address
    vault_token     = var.vault_token
  }
}
```

Alternatively, set via environment variable:
```bash
export VAULT_ORGANIZATION_ID="550e8400-e29b-41d4-a716-446655440000"
waypoint up
```

### With Organization + Team UUID (Hierarchical)

```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name        = context.application.name
    organization_id = var.customer_uuid
    team_id         = var.team_uuid
    vault_address   = var.vault_address
    vault_token     = var.vault_token
  }
}
```

Or via environment variables:
```bash
export VAULT_ORGANIZATION_ID="550e8400-e29b-41d4-a716-446655440000"
export VAULT_TEAM_ID="acme-payments-team"
waypoint up
```

### With Random Suffix

```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name          = context.application.name
    use_random_suffix = true
    vault_address     = var.vault_address
    vault_token       = var.vault_token
  }
}
```

Or via environment variable:
```bash
export VAULT_USE_RANDOM_SUFFIX="true"
waypoint up
```

### With Environment Variable Prefix

```bash
export VAULT_NAMESPACE_PREFIX="production/namespaces/"
export VAULT_ORGANIZATION_ID="${CUSTOMER_ID}"
export VAULT_TEAM_ID="${TEAM_NAME}"
waypoint up
```

The `waypoint.hcl` will automatically read these environment variables and construct hierarchical namespaces.

## Troubleshooting

### "Failed to authenticate with Vault"
- Verify the `vault_address` is correct
- Ensure the `vault_token` has appropriate permissions
- Check network connectivity to Vault

### "Namespace already exists"
- Choose a different `namespace_path`
- Verify the namespace doesn't already exist in Vault

### "Permission denied"
- Ensure your Vault token has permissions to create namespaces
- Check the attached policy allows namespace creation

## Contributing

To extend this module, you can:
- Add additional auth methods (LDAP, JWT, etc.)
- Create additional secrets engines
- Define custom policies for different use cases
- Add support for database dynamic credentials

## License

This module is provided as-is for use with HashiCorp Vault.

## Support

For issues, questions, or contributions, please refer to the project repository.
