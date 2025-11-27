require_relative '../vault'

Puppet::Type.type(:vault_group).provide(:ruby, parent: Puppet::Provider::Vault) do
  desc 'Manage Vault groups.'

  mk_resource_methods

  def self.instances
    []
  end

  def create
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    group_data = {
      'name' => @resource[:name],
      'type' => 'internal',
    }
    group_data['policies'] = @resource[:policies] if @resource[:policies]
    client.post('/v1/identity/group', group_data)
  end

  def destroy
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    group_info = client.get("/v1/identity/group/name/#{@resource[:name]}")
    group_id = group_info['data']['id']
    client.delete("/v1/identity/group/id/#{group_id}")
  end

  def exists?
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    begin
      client.get("/v1/identity/group/name/#{@resource[:name]}")
      true
    rescue Puppet::Error
      false
    end
  end

  def policies
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    group_info = client.get("/v1/identity/group/name/#{@resource[:name]}")
    group_info['data']['policies'] || []
  end

  def policies=(value)
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    group_info = client.get("/v1/identity/group/name/#{@resource[:name]}")
    group_id = group_info['data']['id']
    client.post("/v1/identity/group/id/#{group_id}", 'policies' => value)
  end
end
