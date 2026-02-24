# Terraform Vault Module - Complete Documentation

Welcome to the Terraform no-code module for Vault namespace creation with Organization/Team UUID support.

## 📚 Documentation Guide

### Getting Started

**Start here if you're new to the module:**

1. **[QUICKSTART.md](QUICKSTART.md)** - Get up and running in 5 minutes
   - Basic usage
   - Common patterns
   - Waypoint integration
   - Environment variables reference

2. **[README.md](README.md)** - Complete module documentation
   - Features and prerequisites
   - All usage examples
   - Variable reference
   - Security considerations
   - Troubleshooting

### Collision Avoidance Strategies

**Choose your collision prevention approach:**

- **[COLLISION_AVOIDANCE.md](COLLISION_AVOIDANCE.md)** - Deep dive into three strategies
  - Strategy comparison matrix
  - UUID generation methods
  - Best practices
  - Migration guides

### Organization/Team UUID Implementation

**Learn the recommended approach for multi-tenant systems:**

1. **[ORG_TEAM_IMPLEMENTATION.md](ORG_TEAM_IMPLEMENTATION.md)** - Implementation overview
   - Feature summary
   - Variable reference
   - Usage examples
   - Waypoint integration
   - Best practices

2. **[ORG_TEAM_EXAMPLES.md](ORG_TEAM_EXAMPLES.md)** - Practical examples
   - 8 real-world scenarios
   - Code samples
   - Namespace hierarchies
   - Migration patterns

### Core Configuration Files

**Terraform module files:**

- **[main.tf](main.tf)** - Main resource definitions
  - Vault namespace creation
  - KV secrets engine setup
  - AppRole configuration
  - Policy creation

- **[variables.tf](variables.tf)** - Input variable definitions
  - All module parameters
  - Default values
  - Validation rules
  - Descriptions

- **[outputs.tf](outputs.tf)** - Output values
  - Namespace information
  - Credentials and auth config
  - Generated UUIDs

- **[waypoint.hcl](waypoint.hcl)** - Waypoint add-on configuration
  - Environment variable mapping
  - Addon definition
  - Variable passthrough

- **[policies/app_policy.hcl](policies/app_policy.hcl)** - AppRole policy template
  - Secret CRUD permissions
  - Token renewal capabilities
  - Auth path permissions

## 🚀 Quick Navigation

### Use Cases

**What's your scenario?**

#### 1. Simple Single Deployment
```bash
→ See: QUICKSTART.md → Basic Usage
→ Code: README.md → Example Configuration → Basic Example
```

#### 2. Multi-Tenant SaaS
```bash
→ See: ORG_TEAM_IMPLEMENTATION.md → Usage Examples
→ See: ORG_TEAM_EXAMPLES.md → Example 1: Simple Organization UUID
→ Code: README.md → With Organization UUID (Recommended for Multi-Tenant)
```

#### 3. Enterprise Multi-Organization + Teams
```bash
→ See: ORG_TEAM_EXAMPLES.md → Example 6: Multiple Teams Within Organization
→ See: ORG_TEAM_IMPLEMENTATION.md → Namespace Path Priority
→ Code: main.tf → locals block (namespace path construction)
```

#### 4. Waypoint Deployment
```bash
→ See: QUICKSTART.md → Waypoint Add-on Usage
→ See: README.md → Waypoint Deployment
→ Code: waypoint.hcl (full configuration)
```

#### 5. Preventing Name Collisions
```bash
→ See: COLLISION_AVOIDANCE.md (complete guide)
→ See: ORG_TEAM_IMPLEMENTATION.md → Namespace Path Priority
→ Choose: Strategy 1 (UUID), Strategy 2 (Random), or Strategy 3 (Manual)
```

### Features

**Looking for a specific feature?**

| Feature | Documentation |
|---------|---|
| Basic namespace creation | README.md → Overview |
| UUID-based collision avoidance | ORG_TEAM_IMPLEMENTATION.md |
| Organization scoping | ORG_TEAM_EXAMPLES.md → Examples 1-2 |
| Team hierarchies | ORG_TEAM_EXAMPLES.md → Example 6 |
| Environment variables | QUICKSTART.md → Environment Variables |
| Waypoint add-ons | README.md → Waypoint Deployment |
| AppRole authentication | README.md → Module Variables → AppRole Configuration |
| Namespace prefixes | README.md → Module Variables → Namespace Configuration |
| Random suffix generation | COLLISION_AVOIDANCE.md → Strategy 2 |

### Troubleshooting

**Having issues?**

1. **"Namespace already exists"**
   → COLLISION_AVOIDANCE.md → Troubleshooting

2. **"Permission denied"**
   → README.md → Troubleshooting

3. **"Wrong namespace structure"**
   → ORG_TEAM_IMPLEMENTATION.md → Troubleshooting

4. **"How do I generate UUIDs?"**
   → ORG_TEAM_IMPLEMENTATION.md → Environment Variables Reference
   → COLLISION_AVOIDANCE.md → Generating UUIDs

5. **"How do I migrate from old setup?"**
   → COLLISION_AVOIDANCE.md → Migration Guide
   → ORG_TEAM_IMPLEMENTATION.md → Backward Compatibility

## 📋 Module Variables Quick Reference

### Required

| Variable | Type | Example |
|----------|------|---------|
| `vault_address` | string | `https://vault.example.com:8200` |
| `vault_token` | string | Your admin token |
| `app_name` | string | `payment-service` |

### Organization/Team Scoping (Optional)

| Variable | Type | Use Case |
|----------|------|----------|
| `organization_id` | string | Customer/Organization UUID |
| `team_id` | string | Team within organization |
| `app_id` | string | Specific app UUID |

### Other Options (Optional)

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `namespace_prefix` | string | "" | Prefix all namespaces (e.g., `prod/`) |
| `use_random_suffix` | bool | false | Auto-generate random suffix |
| `namespace_path` | string | "" | Manual namespace override |
| `secrets_engine_path` | string | "secrets" | KV engine mount path |
| `policy_name` | string | "app-policy" | Policy name |
| `token_ttl` | number | 3600 | Token lifetime in seconds |

## 🔗 Namespace Path Examples

### Simple (No Collision Avoidance)
```
app-name
```

### With Organization UUID
```
org-uuid/app-name
```

### With Organization + Team
```
org-uuid/team-uuid/app-name
```

### With Prefix
```
production/app-name
prefix/org-uuid/app-name
prefix/org-uuid/team-uuid/app-name
```

### With Prefix + Environment + Org + Team + App
```
production/customers/org-uuid/team-uuid/app-name
```

## 🔐 Security Notes

- All sensitive variables are marked with `sensitive = true`
- UUIDs and tokens are not logged by default
- Store credentials in environment variables or secrets manager
- Validate organization/team ownership before deployment
- Use TLS verification in production

## 📖 Reading Order by Experience Level

### Beginner
1. QUICKSTART.md
2. README.md (first half)
3. ORG_TEAM_EXAMPLES.md (Example 1)

### Intermediate
1. README.md (complete)
2. ORG_TEAM_IMPLEMENTATION.md
3. main.tf (review code structure)

### Advanced
1. COLLISION_AVOIDANCE.md
2. ORG_TEAM_EXAMPLES.md (all examples)
3. variables.tf + main.tf (detailed implementation)
4. Implement custom patterns

## 💡 Pro Tips

### Tip 1: Store UUIDs Securely
```bash
# Never commit UUIDs to version control
export VAULT_ORGANIZATION_ID="your-uuid"
# Pass via Terraform or Waypoint
```

### Tip 2: Document Your Structure
```
Organization: ACME Corp (acme-corp-uuid)
  ├── Platform Team (platform-team-uuid)
  │   └── database-service
  ├── Payments Team (payments-team-uuid)
  │   └── payment-api
  └── Analytics Team (analytics-team-uuid)
      └── data-processor
```

### Tip 3: Use Waypoint for Consistency
```bash
# All deploys for a customer use same org_id
export VAULT_ORGANIZATION_ID="${CUSTOMER_ID}"
waypoint up  # All services get consistent scoping
```

### Tip 4: Test in Staging First
```bash
export VAULT_NAMESPACE_PREFIX="staging/"
terraform apply  # Test structure
# Then in production:
export VAULT_NAMESPACE_PREFIX="production/"
terraform apply
```

### Tip 5: Version Your Schema
```hcl
# Keep this for reference
locals {
  namespace_version = "v2"  # Added team_id in v2
}
```

## 🔄 Workflow Examples

### SaaS Deployment for New Customer
```bash
# 1. Generate UUID for customer
export VAULT_ORGANIZATION_ID=$(uuidgen)

# 2. Deploy Vault namespace
terraform apply

# 3. Output and store credentials
terraform output -json > credentials.json

# 4. Share namespace path with customer
echo "Namespace: $(terraform output namespace_path)"
```

### Enterprise Team Deployment
```bash
# 1. Set organization and team
export VAULT_ORGANIZATION_ID="acme-corp-uuid"
export VAULT_TEAM_ID="payments-team-uuid"

# 2. Deploy multiple services
for service in payment-api notification-service; do
  terraform apply -var="app_name=$service"
done

# 3. Result: org/team/service namespaces
```

### Waypoint Multi-Service
```bash
# 1. Set organization context
export VAULT_ORGANIZATION_ID="${CUSTOMER_ID}"

# 2. Deploy with Waypoint
waypoint up  # All services use same org context

# 3. Each service gets its namespace
# - org-uuid/api-service
# - org-uuid/worker-service  
# - org-uuid/scheduler-service
```

## 📞 Getting Help

1. **Module Documentation** → README.md
2. **Collision Prevention** → COLLISION_AVOIDANCE.md
3. **Examples** → ORG_TEAM_EXAMPLES.md
4. **Implementation Details** → Review main.tf and variables.tf
5. **Troubleshooting** → See Troubleshooting sections in docs

## 📝 File Structure

```
terraform-vault-vault-app/
├── main.tf                          # Core Terraform configuration
├── variables.tf                     # Input variable definitions
├── outputs.tf                       # Output definitions
├── waypoint.hcl                     # Waypoint add-on config
├── policies/
│   └── app_policy.hcl              # AppRole policy template
├── README.md                        # Complete module documentation
├── QUICKSTART.md                    # Quick start guide
├── COLLISION_AVOIDANCE.md          # Collision prevention strategies
├── ORG_TEAM_IMPLEMENTATION.md      # UUID implementation summary
├── ORG_TEAM_EXAMPLES.md            # Practical examples
└── INDEX.md                         # This file
```

---

**Start with [QUICKSTART.md](QUICKSTART.md) or choose your use case above!**
