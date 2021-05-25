
require File.dirname(__FILE__) + '/../common/vault'

Puppet::Functions.create_function(:vault_lookup_if_exists) do
  dispatch :vault_lookup_if_exists do
    param 'String', :path
    optional_param 'String', :key
  end

  def vault_lookup_if_exists(path, key = nil)
    data = Vault::Client.new.get_if_exists("/v1/#{path}")

    if data.nil?
      return Puppet::Pops::Types::PSensitiveType::Sensitive.new(nil)
    end

    retval = data['data']

    if key && !key.empty? && retval[key].nil?
      return Puppet::Pops::Types::PSensitiveType::Sensitive.new(nil)
    end

    return Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval) if key.nil? || key.empty?

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(retval[key])
  end
end
