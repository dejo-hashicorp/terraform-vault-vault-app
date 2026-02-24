output "namespace_id" {
  description = "The ID of the created Vault namespace"
  value       = vault_namespace.app_namespace.id
}

output "namespace_path" {
  description = "The path of the created Vault namespace"
  value       = vault_namespace.app_namespace.path
}

output "secrets_engine_path" {
  description = "The path of the KV secrets engine"
  value       = vault_mount.kv_secrets.path
}

output "policy_name" {
  description = "The name of the created policy"
  value       = vault_policy.app_policy.name
}

output "auth_method_path" {
  description = "The path of the AppRole auth method"
  value       = vault_auth_backend.approle.path
}

output "role_name" {
  description = "The name of the AppRole role"
  value       = vault_approle_auth_backend_role.app_role.role_name
}

output "role_id" {
  description = "The RoleID of the AppRole"
  value       = vault_approle_auth_backend_role.app_role.role_id
}

output "secret_id" {
  description = "The SecretID for the AppRole (sensitive)"
  value       = vault_approle_auth_backend_role_secret_id.app_secret_id.secret_id
  sensitive   = true
}

output "app_auth_config" {
  description = "The complete AppRole authentication configuration for the application"
  value = {
    namespace  = vault_namespace.app_namespace.id
    role_id    = vault_approle_auth_backend_role.app_role.role_id
    secret_id  = vault_approle_auth_backend_role_secret_id.app_secret_id.secret_id
    auth_path  = vault_auth_backend.approle.path
    vault_addr = var.vault_address
  }
  sensitive = true
}
