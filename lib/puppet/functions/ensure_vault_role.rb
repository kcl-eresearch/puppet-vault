
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:ensure_vault_role) do
  dispatch :ensure_vault_role do
    param 'String', :fqdn
    param 'String', :role
    optional_param 'String', :vault_url
  end

  def ensure_vault_role(fqdn, role, vault_url = nil)
    vault_url ||= call_function('lookup', 'vault::url')['value']
    client = Vault::Client.new(vault_url)
    client.entity_add_policy(fqdn, role)
  end
end
