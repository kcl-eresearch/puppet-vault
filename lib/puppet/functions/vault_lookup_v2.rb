
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_lookup_v2) do
  dispatch :vault_lookup_v2 do
    param 'String', :store
    param 'String', :path
    optional_param 'String', :key
    optional_param 'String', :vault_url
  end

  def vault_lookup_v2(store, path, key = nil, vault_url = nil)
    client = Vault::Client.new(vault_url)
    data = client.get("/v1/#{store}/data/#{path}")
    retval = data['data']['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at location #{store}/data/#{path}"
    end

    if key && !key.empty? && retval[key].nil?
      raise Puppet::Error, "Key #{key} not found in Vault at location #{store}/data/#{path}"
    end

    return Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval) if key.nil? || key.empty?
    Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval[key])
  end
end
