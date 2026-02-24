# Vault Connection Variables
variable "vault_address" {
  description = "The address of the Vault instance"
  type        = string
  sensitive   = true
}

variable "vault_token" {
  description = "The authentication token to use for Vault"
  type        = string
  sensitive   = true
}

variable "vault_namespace" {
  description = "The Vault namespace to authenticate to (optional)"
  type        = string
  default     = ""
}

variable "skip_tls_verify" {
  description = "Skip TLS verification when connecting to Vault"
  type        = bool
  default     = false
}

# Application Information
variable "app_name" {
  description = "The name of the application"
  type        = string
  validation {
    condition     = length(var.app_name) > 0 && length(var.app_name) <= 50
    error_message = "App name must be between 1 and 50 characters."
  }
}

# Namespace Configuration
variable "namespace_path" {
  description = "The path for the new Vault namespace"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace_path))
    error_message = "Namespace path must contain only lowercase letters, numbers, and hyphens."
  }
}

# Secrets Engine Configuration
variable "secrets_engine_path" {
  description = "The path where the KV secrets engine will be mounted"
  type        = string
  default     = "secrets"
}

variable "kv_path" {
  description = "The path within the KV engine where application secrets will be stored"
  type        = string
  default     = "data"
}

# Policy Configuration
variable "policy_name" {
  description = "The name of the policy to create"
  type        = string
  default     = "app-policy"
}

# AppRole Configuration
variable "auth_method_path" {
  description = "The path where AppRole auth method will be mounted"
  type        = string
  default     = "approle"
}

variable "role_name" {
  description = "The name of the AppRole role"
  type        = string
  default     = "app-role"
}

variable "token_ttl" {
  description = "The TTL of tokens issued using this role in seconds"
  type        = number
  default     = 3600
}

variable "token_max_ttl" {
  description = "The max TTL of tokens issued using this role in seconds"
  type        = number
  default     = 86400
}

variable "secret_id_ttl" {
  description = "The TTL of the SecretID in seconds"
  type        = number
  default     = 0
}

variable "bind_secret_id" {
  description = "Whether the role should require a SecretID"
  type        = bool
  default     = true
}
