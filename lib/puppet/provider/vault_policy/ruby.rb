require_relative '../vault'

Puppet::Type.type(:vault_policy).provide(:ruby, parent: Puppet::Provider::Vault) do
  desc 'Manage Vault policies.'

  def self.instances
    client = ::Vault::Client.new

    # Get all Vault groups.
    resources = []
    policies = vault_caller('policy list').split("\n")
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
    client = ::Vault::Client.new
    client.create_policy(@resource[:name], @resource[:content])
    @property_hash[:ensure] = :present
  end

  def destroy
    fqdn = Facter.value('fqdn')
    client = ::Vault::Client.new
    client.remove_policy(fqdn, @resource[:name])
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
