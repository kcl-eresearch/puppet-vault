
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:ensure_vault_roles) do
  dispatch :ensure_vault_roles do
    param 'String', :fqdn
    param 'Array', :roles
    optional_param 'String', :vault_url
  end

  def ensure_vault_roles(fqdn, roles, vault_url = 'https://vault.example.com:8200')
    client = Vault::Client.new(vault_url)
    client.entity_add_policies(fqdn, roles)
  end
end
