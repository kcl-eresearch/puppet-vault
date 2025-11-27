require_relative '../vault'

Puppet::Type.type(:vault_policy).provide(:ruby, parent: Puppet::Provider::Vault) do
  desc 'Manage Vault policies.'

  def self.instances
    []
  end

  def create
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    client.create_policy(@resource[:name], @resource[:content])
  end

  def destroy
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    client.delete_policy(@resource[:name])
  end

  def exists?
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server, @resource[:mount], @resource[:namespace])
    begin
      client.get_policy(@resource[:name])
      true
    rescue Puppet::Error
      false
    end
  end

  mk_resource_methods

  def update_content(value)
    create
    @property_hash[:content] = value
  end
  alias_method :content=, :update_content
end
