# Policy for ${app_name} application
path "${secrets_engine_path}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${secrets_engine_path}/metadata/*" {
  capabilities = ["list"]
}

path "auth/approle/role/+/secret-id" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}
