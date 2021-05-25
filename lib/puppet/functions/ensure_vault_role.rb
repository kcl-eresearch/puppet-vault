
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:ensure_vault_role) do
  dispatch :ensure_vault_role do
    param 'String', :fqdn
    param 'String', :role
  end

  def ensure_vault_role(fqdn, role)
    Vault::Client.new.entity_add_policy(fqdn, role)
  end
end
