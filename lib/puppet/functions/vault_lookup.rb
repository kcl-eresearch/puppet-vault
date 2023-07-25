
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_lookup) do
  dispatch :vault_lookup do
    param 'String', :path
    optional_param 'String', :key
  end

  def vault_lookup(path, key = nil)
    data = Vault::Client.new.get("/v1/#{path}")
    retval = data['data']

    if retval.nil?
      raise Puppet::Error, "Nothing found in Vault at location #{path}"
    end

    if key && !key.empty? && retval[key].nil?
      raise Puppet::Error, "Key #{key} not found in Vault at location #{path}"
    end

    return Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval) if key.nil? || key.empty?

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval[key])
  end
end
