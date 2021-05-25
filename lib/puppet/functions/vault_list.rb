
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_list) do
  dispatch :vault_list do
    param 'String', :path
  end

  def vault_list(path)
    data = Vault::Client.new.get("/v1/#{path}?list=true")
    retval = data['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at location #{path}"
    end

    retval['keys']
  end
end
