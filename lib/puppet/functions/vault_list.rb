require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_list) do
  dispatch :vault_list do
    param 'String', :path
    optional_param 'String', :vault_url
  end

  def vault_list(path, vault_url = nil)
    vault_url ||= call_function('lookup', 'vault::url')['value']
    client = Vault::Client.new(vault_url)
    data = client.get("/v1/#{path}?list=true")
    retval = data['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at location #{path}"
    end

    retval['keys']
  end
end
