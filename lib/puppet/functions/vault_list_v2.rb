
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_list_v2) do
  dispatch :vault_list_v2 do
    param 'String', :store
    param 'String', :path
  end

  def vault_list_v2(store, path)
    data = Vault::Client.new.get("/v1/#{store}/metadata/#{path}?list=true")
    retval = data['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at #{store} location #{path}"
    end

    retval['keys']
  end
end
