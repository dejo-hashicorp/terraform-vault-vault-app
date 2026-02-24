terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
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

# Create a new namespace for the application
resource "vault_namespace" "app_namespace" {
  path = var.namespace_path
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
  policy    = templatefile("${path.module}/policies/app_policy.hcl", {
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
  namespace       = vault_namespace.app_namespace.id
  backend         = vault_auth_backend.approle.path
  role_name       = var.role_name
  policies        = [vault_policy.app_policy.name]
  token_ttl       = var.token_ttl
  token_max_ttl   = var.token_max_ttl
  secret_id_ttl   = var.secret_id_ttl
  bind_secret_id  = var.bind_secret_id
}

# Generate RoleID and SecretID
resource "vault_approle_auth_backend_role_secret_id" "app_secret_id" {
  namespace   = vault_namespace.app_namespace.id
  backend     = vault_auth_backend.approle.path
  role_name   = vault_approle_auth_backend_role.app_role.role_name
  ttl         = var.secret_id_ttl
}
