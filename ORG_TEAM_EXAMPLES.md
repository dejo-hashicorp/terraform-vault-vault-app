# Organization/Team UUID Examples

This file demonstrates practical examples of using organization and team UUIDs with the Vault module.

## Example 1: Simple Organization UUID

**Scenario:** Multi-tenant SaaS where each customer has one app named "api-server"

**Without UUID (Problem):**
```
Customer A deploys: api-server  →  namespace: api-server
Customer B deploys: api-server  →  namespace: api-server  ❌ COLLISION!
```

**With Organization UUID (Solution):**
```hcl
module "customer_a_vault" {
  source = "./"

  app_name        = "api-server"
  organization_id = "uuid-for-customer-a"
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

module "customer_b_vault" {
  source = "./"

  app_name        = "api-server"
  organization_id = "uuid-for-customer-b"
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Results in distinct namespaces:
# - uuid-for-customer-a/api-server
# - uuid-for-customer-b/api-server
```

---

## Example 2: Hierarchical Organization + Team

**Scenario:** Enterprise with multiple organizations and teams, each with similar service names

```hcl
variable "customer_id" {
  description = "The customer/organization UUID"
  type        = string
}

variable "team_name" {
  description = "Team ID within the organization"
  type        = string
}

module "team_vault" {
  source = "./"

  app_name        = "payment-service"
  organization_id = var.customer_id
  team_id         = var.team_name
  namespace_prefix = "production/"
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Resulting namespace path:
# production/{customer_id}/{team_name}/payment-service

# Example with real values:
# production/acme-corp-uuid/payments-team/payment-service
```

**Deployment:**
```bash
terraform apply \
  -var="customer_id=acme-corp-uuid" \
  -var="team_name=payments-team"
```

---

## Example 3: Environment Variable Based Organization ID

**Scenario:** CI/CD pipeline where organization ID comes from environment

```hcl
module "app_vault" {
  source = "./"

  app_name      = "worker-service"
  vault_address = var.vault_address
  vault_token   = var.vault_token
  # organization_id will be read from VAULT_ORGANIZATION_ID env var
}
```

**Deployment Script:**
```bash
#!/bin/bash

# For different deployments
case "${ENVIRONMENT}" in
  production)
    export VAULT_ORGANIZATION_ID="prod-org-uuid"
    ;;
  staging)
    export VAULT_ORGANIZATION_ID="staging-org-uuid"
    ;;
  development)
    export VAULT_ORGANIZATION_ID="dev-org-uuid"
    ;;
esac

terraform apply
```

---

## Example 4: Overriding Organization ID with Explicit app_id

**Scenario:** Need to use a more specific identifier than organization

```hcl
module "app_vault" {
  source = "./"

  app_name        = "api-service"
  organization_id = "acme-corp-uuid"  # This would be used normally
  app_id          = "specific-service-uuid"  # But we override with this
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Resulting namespace:
# specific-service-uuid/api-service
# (app_id takes precedence over organization_id)
```

---

## Example 5: Waypoint Add-on with Organization UUID

**Scenario:** Deploying multiple applications for the same customer via Waypoint

**waypoint.hcl:**
```hcl
variable "customer_uuid" {
  default = ""
  env     = ["CUSTOMER_UUID"]
}

addon {
  pack = "terraform-vault-vault-app"
  
  variables = {
    app_name        = context.application.name
    organization_id = var.customer_uuid
    vault_address   = var.vault_address
    vault_token     = var.vault_token
  }
}
```

**Deployment:**
```bash
export CUSTOMER_UUID="550e8400-e29b-41d4-a716-446655440000"
waypoint up
```

All deployed apps will have their namespaces under the same customer UUID:
- `550e8400-e29b-41d4-a716-446655440000/payment-api`
- `550e8400-e29b-41d4-a716-446655440000/notification-service`
- `550e8400-e29b-41d4-a716-446655440000/data-processor`

---

## Example 6: Multiple Teams Within Organization

**Scenario:** Large organization with separate teams, each managing their own services

```hcl
locals {
  organization_id = "acme-corp-uuid"
  
  teams = {
    platform   = "platform-team-uuid"
    payments   = "payments-team-uuid"
    analytics  = "analytics-team-uuid"
  }
}

# Platform team's database service
module "platform_db" {
  source = "./"

  app_name        = "database-service"
  organization_id = local.organization_id
  team_id         = local.teams.platform
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Payments team's API service
module "payments_api" {
  source = "./"

  app_name        = "api-service"
  organization_id = local.organization_id
  team_id         = local.teams.payments
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Analytics team's processor service
module "analytics_processor" {
  source = "./"

  app_name        = "processor-service"
  organization_id = local.organization_id
  team_id         = local.teams.analytics
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Resulting namespaces:
# - acme-corp-uuid/platform-team-uuid/database-service
# - acme-corp-uuid/payments-team-uuid/api-service
# - acme-corp-uuid/analytics-team-uuid/processor-service
```

---

## Example 7: Generating and Storing Organization UUIDs

**Scenario:** Dynamic organization creation with UUID generation

```hcl
# Generate UUID for new customer
resource "random_uuid" "customer_uuid" {
  keepers = {
    customer_name = var.customer_name
  }
}

# Store mapping
resource "vault_generic_secret" "customer_info" {
  path = "secret/customers/${var.customer_name}/info"

  data_json = jsonencode({
    uuid      = random_uuid.customer_uuid.result
    created   = timestamp()
    namespace = vault_namespace.customer_namespace.path
  })
}

# Deploy Vault namespace for customer
module "customer_vault" {
  source = "./"

  app_name        = "primary-app"
  organization_id = random_uuid.customer_uuid.result
  namespace_prefix = "customers/"
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

output "customer_uuid" {
  value = random_uuid.customer_uuid.result
}

output "namespace_path" {
  value = module.customer_vault.namespace_path
}
```

---

## Example 8: Conditional Organization Scoping

**Scenario:** Different scoping strategy based on environment

```hcl
variable "environment" {
  type = string
}

variable "customer_uuid" {
  type = string
}

variable "team_id" {
  type    = string
  default = ""
}

module "app_vault" {
  source = "./"

  app_name        = "api-service"
  organization_id = var.customer_uuid
  team_id         = var.environment == "production" ? var.team_id : ""
  namespace_prefix = "${var.environment}/"
  vault_address   = var.vault_address
  vault_token     = var.vault_token
}

# Production: prod/{customer_uuid}/{team_id}/api-service
# Development: dev/{customer_uuid}/api-service
```

---

## Best Practices

### 1. **Use Consistent UUID Format**
```bash
# Generate UUIDs with consistent tool/format
export VAULT_ORGANIZATION_ID=$(uuidgen)

# Or use existing system identifiers
export VAULT_ORGANIZATION_ID="acme-corp"
export VAULT_TEAM_ID="payments-team"
```

### 2. **Document the UUID Mapping**
```hcl
locals {
  organization_uuids = {
    "Acme Corp"        = "550e8400-e29b-41d4-a716-446655440000"
    "Beta Industries"  = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    "Gamma Services"   = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
  }
}
```

### 3. **Store UUIDs Securely**
```bash
# In environment or secrets manager, never in code
export VAULT_ORGANIZATION_ID="${CUSTOMER_ID}"
export VAULT_TEAM_ID="${TEAM_ID}"
```

### 4. **Validate Organization Ownership**
```hcl
# Verify caller has permission to use this organization_id
variable "organization_id" {
  validation {
    condition = (
      var.organization_id == "" ||
      contains(var.allowed_organization_ids, var.organization_id)
    )
    error_message = "Invalid organization ID"
  }
}
```

### 5. **Audit Organization Namespace Access**
```bash
# Log who deployed what under which organization
vault audit enable file file_path=/var/log/vault-audit.log

# Periodically review:
vault audit list
```

---

## Namespace Hierarchy Examples

### Two-Level (Organization + App)
```
organization-uuid/app-name
├── org-a-uuid/payment-api
├── org-a-uuid/notification-service
├── org-b-uuid/payment-api
└── org-b-uuid/worker-service
```

### Three-Level (Organization + Team + App)
```
organization-uuid/team-id/app-name
├── acme-corp/platform/database
├── acme-corp/platform/cache
├── acme-corp/payments/api
└── acme-corp/payments/processor
```

### Four-Level (Environment + Org + Team + App)
```
environment/organization-uuid/team-id/app-name
├── production/acme-corp/platform/database
├── staging/acme-corp/platform/database
├── production/acme-corp/payments/api
└── staging/acme-corp/payments/api
```

---

## Migration from app_id to organization_id

If you have existing deployments using `app_id` and want to migrate to the more explicit `organization_id`:

```hcl
# Old approach
module "legacy" {
  source = "./"
  app_id = "some-uuid"
}

# New approach (equivalent)
module "modern" {
  source = "./"
  organization_id = "some-uuid"
}

# Both result in the same namespace!
# This allows gradual migration.
```

The module automatically falls back from `app_id` to `organization_id`, so both approaches are supported simultaneously during migration.
