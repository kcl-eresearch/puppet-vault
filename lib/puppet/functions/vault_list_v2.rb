
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_list_v2) do
  dispatch :vault_list_v2 do
    param 'String', :store
    param 'String', :path
    optional_param 'String', :vault_url
  end

  def vault_list_v2(store, path, vault_url = 'https://vault.example.com:8200')
    data = Vault::Client.new(vault_url).get("/v1/#{store}/metadata/#{path}?list=true")
    retval = data['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at #{store} location #{path}"
    end

    retval['keys']
  end
end
