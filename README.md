# vault

## vault_lookup

Usage:

$r10k_hook = vault_lookup('puppet/r10k_token', 'token', 'https://vault.local:8200', false)

Or:


$r10k_hook = Deferred('vault_lookup', ['puppet/r10k_token', 'token', 'https://vault.local:8200', false])
