# vault


## Setting up authentication

You will need

* Root Token

* Access to Vault API on 8200 OR SSH access to the Vault Server

### Vault Local

When managing policy on a Vault server you will need to configure a certrole to allow the local puppet certificate to authenticate to Vault

Login to Vault

```bash
# TLS Skip verify should only be used when using ssh
vault login -tls-skip-verify
```

Create the [Vault Local Server Policy](files/local.hcl)

```bash
vault policy write vault/local files/local.hcl
```

Create the certrole auth method at the default path if not already enabled

```bash
vault auth enable cert
```

Configure Certificate role

```hcl
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

## vault_lookup

Usage:

$r10k_hook = vault_lookup('puppet/r10k_token', 'token')
