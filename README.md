# Terraform Vault No-Code Module

A Terraform no-code module that creates isolated Vault namespaces for applications. This module enables applications to have their own dedicated secret storage and authentication mechanisms within an existing Vault instance. Designed to be deployed as a Waypoint add-on.

## Overview

This module provisions:
- **Vault Namespace**: An isolated namespace for the application
- **KV Secrets Engine**: A KV v2 secrets engine within the namespace
- **AppRole Authentication**: An AppRole auth method for secure application authentication
- **Policy**: A policy defining access permissions for the application
- **Secret Management**: Automated generation of RoleID and SecretID for application access

## Features

- 🔐 Isolated secret storage per application
- 🎯 AppRole authentication for secure service-to-service communication
- ⚙️ No-code deployment via Waypoint add-ons
- 🔑 Automatic credential generation
- 🛡️ Policy-based access control
- 📝 Configurable TTLs and security settings

## Prerequisites

- Terraform >= 1.0
- Vault >= 1.8 with admin access
- Valid Vault token with appropriate permissions
- Waypoint >= 1.0 (for add-on deployment)

## Usage

### Direct Terraform Usage

```hcl
module "vault_app_namespace" {
  source = "./"

  app_name      = "my-application"
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
  namespace_path = "my-app-ns"
}
```

### Via Waypoint Add-on

```hcl
addon {
  pack = "terraform-vault-vault-app"

  variables = {
    app_name           = "my-application"
    vault_address      = "https://vault.example.com:8200"
    vault_token        = var.vault_token
    namespace_path     = "my-app-ns"
  }
}
```

## Module Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vault_address` | string | The address of the Vault instance (e.g., https://vault.example.com:8200) |
| `vault_token` | string | The authentication token for Vault (sensitive) |
| `app_name` | string | The name of the application (1-50 characters) |
| `namespace_path` | string | The path for the new Vault namespace (lowercase letters, numbers, hyphens only) |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
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

### Basic Example

```hcl
module "app_vault" {
  source = "./"

  app_name       = "payment-service"
  vault_address  = "https://vault.internal.company.com:8200"
  vault_token    = var.vault_admin_token
  namespace_path = "payment-service-ns"
}

output "app_credentials" {
  value     = module.app_vault.app_auth_config
  sensitive = true
}
```

### With Custom Settings

```hcl
module "app_vault" {
  source = "./"

  app_name           = "database-migrate"
  vault_address      = "https://vault.internal.company.com:8200"
  vault_token        = var.vault_admin_token
  namespace_path     = "db-migrate-ns"
  policy_name        = "db-migrate-policy"
  secrets_engine_path = "db-secrets"
  token_ttl          = 1800  # 30 minutes
  token_max_ttl      = 43200 # 12 hours
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

1. **Reference the add-on** in your Waypoint configuration:
```hcl
addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name           = context.application.name
    vault_address      = var.vault_address
    vault_token        = var.vault_token
    namespace_path     = "${context.application.name}-ns"
  }
}
```

2. **Deploy** with your application:
```bash
waypoint up
```

3. **Access the credentials** from the deployment outputs

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
