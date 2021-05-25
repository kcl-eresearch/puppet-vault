require_relative '../vault'

Puppet::Type.type(:vault_group).provide(:ruby, parent: Puppet::Provider::Vault) do
  desc 'Manage Vault groups.'

  mk_resource_methods

  def self.instances
    # Get all Vault groups.
    client = connect
    groups = client.get('/identity/group/name?list=true')
    groups['data']['keys'].each do |group|
      new(name: group,
          ensure: :present)
    end
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end
end
