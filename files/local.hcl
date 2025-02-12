## Vault local Puppet certificate Policy

# Allow token to look itself up
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow sub tokens to be created
path "auth/token/create" {
  capabilities = ["update"]
}

# Allow Vault server to revoke tokens
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# Allow Vault to create policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/auth" {
  capabilities = ["read"]
}
