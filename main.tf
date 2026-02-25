terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "vault" {
  address         = var.vault_address
  token           = var.vault_token
  namespace       = var.vault_namespace
  skip_tls_verify = var.skip_tls_verify
}

# Generate random suffix for uniqueness if use_random_suffix is enabled
resource "random_id" "namespace_suffix" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

# Determine the namespace path
locals {
  # Check if we have app_id (explicit or from organization_id)
  has_explicit_app_id = var.app_id != ""
  has_org_id          = var.organization_id != ""
  has_team_id         = var.team_id != ""
  has_prefix          = var.namespace_prefix != ""
  has_manual_path     = var.namespace_path != ""

  # Construct full namespace path with priority order:
  # 1. Manual path override
  # 2. Org + Team + app_id
  # 3. app_id alone
  # 4. Org + Team
  # 5. Org alone
  # 6. Random suffix
  # 7. Default (just app_name)
  prefix_with_slash = local.has_prefix ? "${trimsuffix(var.namespace_prefix, "/")}" : ""
  
  computed_namespace_path = trimregex("/$", (
    local.has_manual_path ? var.namespace_path : (
      local.has_org_id && local.has_team_id && local.has_explicit_app_id ? "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.organization_id}/${var.team_id}/${var.app_id}/${var.app_name}" : (
        local.has_explicit_app_id ? "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.app_id}/${var.app_name}" : (
          local.has_org_id && local.has_team_id ? "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.organization_id}/${var.team_id}/${var.app_name}" : (
            local.has_org_id ? "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.organization_id}/${var.app_name}" : (
              var.use_random_suffix ? "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.app_name}-${random_id.namespace_suffix[0].hex}" : (
                "${local.prefix_with_slash}${local.prefix_with_slash != "" ? "/" : ""}${var.app_name}"
              )
            )
          )
        )
      )
    )
  ))
}

# Create a new namespace for the application
resource "vault_namespace" "app_namespace" {
  path = local.computed_namespace_path
}

# Create a KV secrets engine for the application
resource "vault_mount" "kv_secrets" {
  namespace   = vault_namespace.app_namespace.id
  path        = var.secrets_engine_path
  type        = "kv"
  description = "KV Secrets engine for ${var.app_name}"

  options = {
    version = "2"
  }
}

# Create a policy for the application
resource "vault_policy" "app_policy" {
  namespace = vault_namespace.app_namespace.id
  name      = var.policy_name
  policy = templatefile("${path.module}/policies/app_policy.hcl", {
    app_name            = var.app_name
    secrets_engine_path = var.secrets_engine_path
    kv_path             = var.kv_path
  })
}

# Create an auth method (AppRole)
resource "vault_auth_backend" "approle" {
  namespace = vault_namespace.app_namespace.id
  type      = "approle"
  path      = var.auth_method_path
}

# Create an AppRole role for the application
resource "vault_approle_auth_backend_role" "app_role" {
  namespace      = vault_namespace.app_namespace.id
  backend        = vault_auth_backend.approle.path
  role_name      = var.role_name
  token_policies = [vault_policy.app_policy.name]
  token_ttl      = var.token_ttl
  token_max_ttl  = var.token_max_ttl
  secret_id_ttl  = var.secret_id_ttl
  bind_secret_id = var.bind_secret_id
}

# Generate RoleID and SecretID
resource "vault_approle_auth_backend_role_secret_id" "app_secret_id" {
  namespace = vault_namespace.app_namespace.id
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.app_role.role_name
  ttl       = var.secret_id_ttl
}
