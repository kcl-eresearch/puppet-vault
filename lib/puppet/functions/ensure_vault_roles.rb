
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:ensure_vault_roles) do
  dispatch :ensure_vault_roles do
    param 'String', :fqdn
    param 'Array', :roles
  end

  def ensure_vault_roles(fqdn, roles)
    Vault::Client.new.entity_add_policies(fqdn, roles)
  end
end
