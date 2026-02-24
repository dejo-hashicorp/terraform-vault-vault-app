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
variable "namespace_prefix" {
  description = "The prefix path for the Vault namespace (e.g., 'ns1/cns2/') - defaults to empty. Can be set via VAULT_NAMESPACE_PREFIX env var"
  type        = string
  default     = ""
}

variable "app_id" {
  description = "A unique identifier for the application (UUID, organization ID, team ID, etc.). Used to avoid namespace collisions. When provided, namespace becomes: {prefix}/{app_id}/{app_name}. Can be set via VAULT_APP_ID environment variable."
  type        = string
  default     = ""
  sensitive   = true
}

variable "organization_id" {
  description = "Organization or customer UUID (deprecated - use app_id instead). Falls back to app_id if app_id is empty."
  type        = string
  default     = ""
  sensitive   = true
}

variable "team_id" {
  description = "Team ID for additional namespace scoping. When both organization_id and team_id are provided, namespace becomes: {prefix}/{organization_id}/{team_id}/{app_name}"
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_random_suffix" {
  description = "If true, appends a random hex suffix to the namespace path for uniqueness: {prefix}{app_name}-{random}. Ignored if app_id is provided"
  type        = bool
  default     = false
}

variable "namespace_path" {
  description = "Override for the complete path for the new Vault namespace (auto-generated from prefix + app_name if not provided)"
  type        = string
  default     = ""
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
