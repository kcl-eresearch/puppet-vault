
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_lookup_if_exists_v2) do
  dispatch :vault_lookup_if_exists_v2 do
    param 'String', :store
    param 'String', :path
    optional_param 'String', :key
    optional_param 'String', :vault_url
  end

  def vault_lookup_if_exists_v2(store, path, key = nil, vault_url = nil)
    client = Vault::Client.new(vault_url)
    data = client.get_if_exists("/v1/#{store}/data/#{path}")
    if data.nil?
      return Puppet::Pops::Types::PSensitiveType::Sensitive.new(nil)
    end

    retval = data['data']['data']

    if key && !key.empty? && retval[key].nil?
      return Puppet::Pops::Types::PSensitiveType::Sensitive.new(nil)
    end

    return Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval) if key.nil? || key.empty?

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval[key])
  end
end
