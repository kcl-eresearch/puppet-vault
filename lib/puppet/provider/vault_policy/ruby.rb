require_relative '../vault'

Puppet::Type.type(:vault_policy).provide(:ruby, parent: Puppet::Provider::Vault) do
  desc 'Manage Vault policies.'

  def self.instances
    # Use the local FQDN as the default vault server
    vault_server = "https://#{Facter.value('fqdn')}:8200"

    resources = []
    begin
      client = ::Vault::Client.new(vault_server)
      policies = client.get('/v1/sys/policies/acl?list=true')['data']['keys']
      policies.each do |pol|
        polcontent = client.get_policy(pol)
        resources.push(
          new(
            name: pol,
            ensure: :present,
            content: polcontent,
          ),
        )
      end
    rescue StandardError => e
      Puppet.warning("Failed to get vault policies: #{e.message}")
      resources
    end
    resources
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def create
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server)
    client.create_policy(@resource[:name], @resource[:content])
    @property_hash[:ensure] = :present
  end

  def destroy
    vault_server = "https://#{Facter.value('fqdn')}:8200"
    client = ::Vault::Client.new(vault_server)
    client.delete_policy(@resource[:name])
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end

  mk_resource_methods

  def update_content(value)
    create
    @property_hash[:content] = value
  end
  alias_method :content=, :update_content
end
