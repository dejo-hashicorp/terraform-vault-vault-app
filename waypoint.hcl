project = "vault-vault-app"

variable "app_name" {
  default     = ""
  type        = string
  description = "The name of the application that will use this Vault namespace"
}

variable "vault_address" {
  default     = ""
  type        = string
  description = "The address of the Vault instance"
  env         = ["VAULT_ADDR"]
}

variable "vault_token" {
  default     = ""
  type        = string
  description = "The authentication token for Vault"
  sensitive   = true
  env         = ["VAULT_TOKEN"]
}

variable "vault_namespace" {
  default     = ""
  type        = string
  description = "The parent Vault namespace"
}

variable "namespace_prefix" {
  default     = ""
  type        = string
  description = "The prefix path for the Vault namespace (e.g., 'ns1/cns2/')"
  env         = ["VAULT_NAMESPACE_PREFIX"]
}

variable "app_id" {
  default     = ""
  type        = string
  description = "A unique identifier for the application (UUID, organization ID, etc.)"
  env         = ["VAULT_APP_ID"]
  sensitive   = true
}

variable "organization_id" {
  default     = ""
  type        = string
  description = "Organization or customer UUID"
  env         = ["VAULT_ORGANIZATION_ID"]
  sensitive   = true
}

variable "team_id" {
  default     = ""
  type        = string
  description = "Team ID for additional namespace scoping"
  env         = ["VAULT_TEAM_ID"]
  sensitive   = true
}

variable "use_random_suffix" {
  default     = false
  type        = bool
  description = "Enable random suffix for namespace uniqueness"
  env         = ["VAULT_USE_RANDOM_SUFFIX"]
}

variable "namespace_path" {
  default     = ""
  type        = string
  description = "The complete path for the new Vault namespace (optional override)"
}

variable "skip_tls_verify" {
  default     = false
  type        = bool
  description = "Skip TLS verification"
}

# Add-on configuration
addon {
  pack = file("${path.module}")

  variables = {
    app_name           = var.app_name
    vault_address      = var.vault_address
    vault_token        = var.vault_token
    vault_namespace    = var.vault_namespace
    namespace_prefix   = var.namespace_prefix
    app_id             = var.app_id
    organization_id    = var.organization_id
    team_id            = var.team_id
    use_random_suffix  = var.use_random_suffix
    namespace_path     = var.namespace_path
    skip_tls_verify    = var.skip_tls_verify
  }
}
