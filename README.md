# puppet-vault

A Puppet module for managing HashiCorp Vault policies and groups, with support for Vault namespaces.

## Table of Contents

- [Setting up authentication](#setting-up-authentication)
- [Resource Types](#resource-types)
  - [vault_policy](#vault_policy)
  - [vault_group](#vault_group)
- [Functions](#functions)
  - [vault_lookup](#vault_lookup)
  - [vault_lookup_if_exists](#vault_lookup_if_exists)

## Setting up authentication

### Prerequisites

* Root Token or sufficient permissions to configure authentication
* Access to Vault API on port 8200 OR SSH access to the Vault Server

### Vault Local

When managing policies on a Vault server, you need to configure a certificate role to allow the local Puppet certificate to authenticate to Vault.

#### Login to Vault

```bash
# TLS Skip verify should only be used when using SSH on localhost
vault login -tls-skip-verify
```

#### Create the Vault Local Server Policy

Apply the [Vault Local Server Policy](files/local.hcl):

```bash
vault policy write vault/local files/local.hcl
```

#### Enable Certificate Authentication

Create the certificate auth method at the default path (if not already enabled):

```bash
vault auth enable cert
```

#### Configure Certificate Role

```bash
CERT_CN="$(hostname).example.com"
vault write auth/cert/certs/vault-server \
    display_name="Vault Local Puppet Certificate" \
    token_policies="vault/local" \
    certificate=@/etc/puppetlabs/puppet/ssl/certs/ca.pem \
    allowed_common_names="${CERT_CN}" \
    allowed_dns_sans="${CERT_CN}" \
    token_ttl="1h" \
    token_bound_cidrs="127.0.0.1" \
    token_max_ttl="24h"
```

## Resource Types

### vault_policy

Manages Vault ACL policies.

#### Parameters

- `name` (namevar): The name of the policy
- `ensure`: Whether the policy should exist (present/absent)
- `content`: The policy content in HCL format
- `namespace`: (Optional) The Vault namespace to use

#### Examples

```puppet
# Basic policy
vault_policy { 'my-app-policy':
  ensure  => present,
  content => @(EOT)
    path "secret/data/myapp/*" {
      capabilities = ["read", "list"]
    }
    | EOT
}

# Policy in a namespace
vault_policy { 'dev-policy':
  ensure    => present,
  namespace => 'development',
  content   => @(EOT)
    path "secret/data/dev/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    | EOT
}
```

### vault_group

Manages Vault identity groups.

#### Parameters

- `name` (namevar): The name of the group
- `ensure`: Whether the group should exist (present/absent)
- `policies`: The policies assigned to the group
- `namespace`: (Optional) The Vault namespace to use

#### Examples

```puppet
vault_group { 'developers':
  ensure   => present,
  policies => ['dev-policy', 'read-only'],
}

# Group in a namespace
vault_group { 'prod-admins':
  ensure    => present,
  namespace => 'production',
  policies  => ['admin-policy'],
}
```

## Functions

### vault_lookup

Retrieves a secret value from Vault.

#### Usage

```puppet
# Retrieve a specific field from a secret
$r10k_hook = vault_lookup('puppet/r10k_token', 'token')

# Retrieve a database password
$db_password = vault_lookup('secret/data/database', 'password')
```

### vault_lookup_if_exists

Retrieves a secret value from Vault if it exists, returns `nil` if the secret doesn't exist.

#### Usage

```puppet
# Safely lookup a secret that might not exist
$optional_token = vault_lookup_if_exists('puppet/optional_token', 'token')

if $optional_token {
  # Use the token if it exists
  notify { "Token found: ${optional_token}": }
} else {
  # Handle the case where it doesn't exist
  notify { 'No token configured': }
}
```

## Namespace Support

This module supports Vault namespaces. You can specify a namespace for both policies and groups using the `namespace` parameter. When specified, all Vault API requests will be made within that namespace context using the `X-Vault-Namespace` header.

### Example with Namespaces

```puppet
# Create policies in different namespaces
vault_policy { 'dev-secrets':
  ensure    => present,
  namespace => 'development',
  content   => file('mymodule/dev-policy.hcl'),
}

vault_policy { 'prod-secrets':
  ensure    => present,
  namespace => 'production',
  content   => file('mymodule/prod-policy.hcl'),
}

# Create groups in namespaces
vault_group { 'dev-team':
  ensure    => present,
  namespace => 'development',
  policies  => ['dev-secrets'],
}
```

## License

Apache-2.0
