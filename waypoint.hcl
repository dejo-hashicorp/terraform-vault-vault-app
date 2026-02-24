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

variable "namespace_path" {
  default     = ""
  type        = string
  description = "The path for the new Vault namespace"
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
    namespace_path     = var.namespace_path
    skip_tls_verify    = var.skip_tls_verify
  }
}
