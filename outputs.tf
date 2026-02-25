output "namespace_id" {
  description = "The ID of the created Vault namespace"
  value       = vault_namespace.app_namespace.id
}

output "namespace_path" {
  description = "The path of the created Vault namespace"
  value       = vault_namespace.app_namespace.path
  sensitive   = true
}

output "app_id" {
  description = "The resolved unique application ID used for collision avoidance (provided app_id, organization_id, or generated random suffix)"
  value = (
    var.app_id != "" ? var.app_id : (
      var.organization_id != "" ? var.organization_id : (
        var.use_random_suffix ? random_id.namespace_suffix[0].hex : ""
      )
    )
  )
  sensitive = true
}

output "organization_id" {
  description = "The organization ID if provided"
  value       = var.organization_id != "" ? var.organization_id : null
  sensitive   = true
}

output "team_id" {
  description = "The team ID if provided"
  value       = var.team_id != "" ? var.team_id : null
  sensitive   = true
}

output "generated_random_suffix" {
  description = "The generated random suffix if use_random_suffix is enabled"
  value       = var.use_random_suffix ? random_id.namespace_suffix[0].hex : null
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
