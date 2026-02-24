# Namespace Collision Avoidance Strategies

This document explains the three strategies available to prevent namespace collisions when deploying the Vault module for multiple applications.

## Problem

When deploying isolated namespaces for applications, name collisions can occur:

```
User A deploys: app-a  →  namespace: app-a
User B deploys: app-a  →  namespace: app-a  ❌ COLLISION!
```

## Solution: Three Strategies

### 1. **Organization/Team UUID (Recommended for Multi-Tenant)**

Use a unique identifier (UUID, organization ID, team ID) to scope each namespace.

**Namespace Path:** `{prefix}/{app_id}/{app_name}`

**Example:**
```hcl
module "app_vault" {
  source = "./"

  app_name      = "app-a"
  app_id        = "550e8400-e29b-41d4-a716-446655440000"  # Customer UUID
  vault_address = "https://vault.example.com:8200"
  vault_token   = var.vault_admin_token
  namespace_prefix = "customers/"
  # Results in: customers/550e8400-e29b-41d4-a716-446655440000/app-a
}
```

**When to Use:**
- Multi-tenant SaaS platforms
- Organizations/Teams managing their own applications
- When you have a unique identifier for each user/organization
- Best for maintaining clear ownership and isolation

**Advantages:**
- ✅ Clear ownership hierarchy
- ✅ Scalable to many organizations
- ✅ Deterministic and reproducible
- ✅ Easy to audit and track

**Disadvantages:**
- ❌ Requires external UUID source
- ❌ More complex namespace paths
- ❌ Must store UUID securely

**Implementation:**
```bash
# Store UUID as environment variable
export VAULT_APP_ID="org-123-uuid"

# Or use in Waypoint
addon {
  pack = "terraform-vault-vault-app"
  variables = {
    app_name = context.application.name
    app_id   = var.customer_uuid
  }
}
```

---

### 2. **Random Suffix (Simple Alternative)**

Automatically append a random hex suffix to the namespace path.

**Namespace Path:** `{prefix}{app_name}-{random}`

**Example:**
```hcl
module "app_vault" {
  source = "./"

  app_name          = "app-a"
  use_random_suffix = true
  vault_address     = "https://vault.example.com:8200"
  vault_token       = var.vault_admin_token
  # Results in: app-a-a1b2c3d4 (4-byte random hex)
}
```

**When to Use:**
- Simple deployments with fewer naming concerns
- When you don't have an external UUID source
- For temporary or testing environments
- One-off deployments where uniqueness matters but ownership doesn't

**Advantages:**
- ✅ Automatic uniqueness
- ✅ No external ID needed
- ✅ Simple to enable (boolean flag)
- ✅ Good for rapid deployments

**Disadvantages:**
- ❌ Non-deterministic (changes on each apply)
- ❌ Harder to audit
- ❌ Less meaningful namespace paths
- ❌ Can't easily reproduce the same namespace

**Implementation:**
```bash
# Enable via environment variable
export VAULT_USE_RANDOM_SUFFIX="true"

# Or in Terraform
variable "use_random_suffix" {
  default = true
}

# Or in Waypoint
addon {
  pack = "terraform-vault-vault-app"
  variables = {
    app_name          = context.application.name
    use_random_suffix = true
  }
}
```

---

### 3. **Manual Namespace Path Override (Maximum Control)**

Specify the exact namespace path explicitly, bypassing all auto-generation logic.

**Namespace Path:** Whatever you specify

**Example:**
```hcl
module "app_vault" {
  source = "./"

  app_name       = "app-a"
  namespace_path = "production/team-a/payment-service-v2"
  vault_address  = "https://vault.example.com:8200"
  vault_token    = var.vault_admin_token
  # Results in exactly: production/team-a/payment-service-v2
}
```

**When to Use:**
- When you need precise control over namespace paths
- Complex organizational hierarchies
- Migration scenarios with specific naming requirements
- When combining with other tooling that generates paths

**Advantages:**
- ✅ Maximum control
- ✅ Can match any naming convention
- ✅ Fully deterministic
- ✅ No surprises

**Disadvantages:**
- ❌ Manual burden
- ❌ No automatic collision avoidance
- ❌ Must manage uniqueness yourself
- ❌ Error-prone

**Implementation:**
```bash
# Use Terraform variable
terraform apply -var="namespace_path=org-123/app-a"

# Or in waypoint.hcl
addon {
  pack = "terraform-vault-vault-app"
  variables = {
    app_name       = context.application.name
    namespace_path = "${var.customer_org}/${var.team}/${context.application.name}"
  }
}
```

---

## Strategy Comparison Matrix

| Feature | UUID (app_id) | Random Suffix | Manual Path |
|---------|---------------|---------------|-------------|
| **Deterministic** | ✅ Yes | ❌ No | ✅ Yes |
| **Automatic** | ✅ Yes (if UUID provided) | ✅ Yes | ❌ No |
| **Ownership Clear** | ✅ Yes | ❌ No | ✅ Yes (if well-named) |
| **Scalable** | ✅ Yes | ✅ Yes | ⚠️ Depends |
| **Auditability** | ✅ High | ⚠️ Medium | ✅ High |
| **Complexity** | ⚠️ Medium | ✅ Low | ⚠️ Medium |
| **Best For** | Multi-tenant | Simple deploys | Complex orgs |

---

## Generating UUIDs

### Using Terraform Built-in
```hcl
app_id = uuidv4()  # Generates UUID each apply (not recommended for production)
```

### Using CLI Tools
```bash
# macOS
export VAULT_APP_ID=$(uuidgen)

# Linux
export VAULT_APP_ID=$(uuid)

# UUID library (cross-platform)
export VAULT_APP_ID=$(python -c "import uuid; print(uuid.uuid4())")
```

### Using Environment Variables (Recommended for Production)
```bash
# Set once and reuse
export VAULT_APP_ID="550e8400-e29b-41d4-a716-446655440000"

# Pass to Terraform
terraform apply
```

### Using External Systems
```hcl
# From Vault lookup
data "vault_generic_secret" "customer_id" {
  path = "secret/customers/${var.customer_name}/id"
}

module "app_vault" {
  source = "./"
  app_id = data.vault_generic_secret.customer_id.data["uuid"]
}
```

---

## Best Practices

### 1. **Choose One Strategy Per Organization**
Don't mix strategies across your deployments. Pick one and standardize:
- **SaaS/Multi-tenant:** Use UUID (app_id)
- **Internal/Simple:** Use Random suffix or Manual path
- **Complex/Legacy:** Use Manual path with structured naming

### 2. **Store UUIDs Securely**
If using app_id, treat it like sensitive data:
```hcl
variable "app_id" {
  description = "Customer/Organization UUID"
  type        = string
  sensitive   = true
}
```

### 3. **Document Your Scheme**
Create a naming convention document:
```
Format: {environment}/{customer_uuid}/{service_name}
Example: production/550e8400-e29b-41d4-a716-446655440000/payment-api
```

### 4. **Track Namespace Mappings**
Maintain an inventory:
```
| Namespace | Customer | Service | Deployed | Status |
|-----------|----------|---------|----------|--------|
| prod/550e8400.../payment-api | Acme Corp | Payment | 2024-01-15 | Active |
```

### 5. **Backup UUID Mappings**
If using random suffixes, capture the output immediately:
```bash
terraform apply | tee deployment.log
# Extract and store: generated_random_suffix = a1b2c3d4
```

### 6. **Plan for Migration**
Have a strategy to transition between methods if needed:
- Add manual paths as escape hatch
- Maintain backward compatibility
- Plan migration timeline

---

## Examples by Use Case

### Multi-Tenant SaaS
```hcl
# Each customer gets their own UUID
customer_uuid = data.external.get_customer_uuid.result["id"]

module "vault" {
  source = "./"
  app_id = customer_uuid
  namespace_prefix = "customers/"
  app_name = context.application.name
}
```

### CI/CD Pipeline
```bash
#!/bin/bash
# Generate per-build namespace
BUILD_UUID=$(uuidgen)
terraform apply -var="app_id=${BUILD_UUID}"
```

### Simple Single-Organization
```hcl
# Just use random suffix for uniqueness
module "vault" {
  source = "./"
  use_random_suffix = true
  app_name = context.application.name
}
```

### Complex Enterprise
```hcl
# Full path with department/team/service/version
namespace_path = "prod/${var.dept}/${var.team}/${var.service}/${var.version}"
```

---

## Migration Guide

### From No Collision Avoidance → With UUID

1. **Audit existing namespaces:**
   ```bash
   vault namespace list -format=json
   ```

2. **Create new namespaces with UUIDs:**
   ```hcl
   module "migrated_service" {
     source = "./"
     app_id = "new-uuid-for-service"
     namespace_path = "migrated/${var.service_uuid}/${var.service_name}"
   }
   ```

3. **Migrate secrets:**
   ```bash
   # Export from old namespace
   vault kv get -format=json old-namespace/secrets > backup.json
   
   # Import to new namespace
   vault kv put new-namespace/secrets @backup.json
   ```

4. **Update consumers:**
   - Update app configurations with new namespace paths
   - Test in staging first
   - Schedule cutover

---

## Troubleshooting

### Namespace Already Exists
```
Error: namespace already exists
```
**Solution:** Use different strategy:
- Add UUID if not using one
- Enable random suffix
- Specify unique manual path

### Lost Namespace Path
**Recovery options:**
1. Check Terraform state: `terraform show`
2. List all namespaces: `vault namespace list -format=json`
3. Look for your app name in list
4. Recreate module with explicit path: `-var="namespace_path=..."`

### UUID Conflicts
```
Error: namespace path conflict
```
**Solution:** UUID is not unique enough. Use longer UUIDs or add additional identifiers.

---

## Summary

| Strategy | Use This | If You... |
|----------|----------|----------|
| **UUID (app_id)** | Have multiple customers/orgs each with same app names |
| **Random Suffix** | Need simple automatic uniqueness without external IDs |
| **Manual Path** | Have complex requirements or organizational structure |

**Recommended Default:** Use `app_id` with UUIDs for multi-tenant systems, random suffix for simple cases.
