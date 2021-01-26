Puppet::Functions.create_function(:vault_lookup) do
  dispatch :vault_lookup do
    param 'String', :path
    optional_param 'String', :key
    optional_param 'String', :vault_url
    optional_param 'Boolean', :verify_ssl
    optional_param 'String', :local_token
  end

  def vault_lookup(path, key = nil, vault_url = nil, verify_ssl = true, local_token = nil)
    if vault_url.nil?
      Puppet.debug 'No Vault address was set on function, defaulting to value from VAULT_ADDR env value'
      vault_url = ENV['VAULT_ADDR']
      raise Puppet::Error, 'No vault_url given and VAULT_ADDR env variable not set' if vault_url.nil?
    end

    uri = URI(vault_url)
    # URI is used here to just parse the vault_url into a host string
    # and port; it's possible to generate a URI::Generic when a scheme
    # is not defined, so double check here to make sure at least
    # host is defined.
    raise Puppet::Error, "Unable to parse a hostname from #{vault_url}" unless uri.hostname

    use_ssl = uri.scheme == 'https'
    ssl_context = create_ssl_context(verify_ssl)
    connection = Puppet::Network::HttpPool.connection(uri.host, uri.port, use_ssl: use_ssl, ssl_context: ssl_context)

    token = if local_token.nil?
              get_auth_token(connection)
            else
              get_local_auth_token(local_token)
            end

    secret_response = connection.get("/v1/#{path}", 'X-Vault-Token' => token)
    unless secret_response.is_a?(Net::HTTPOK)
      message = "Received #{secret_response.code} response code from vault at #{uri.host} for secret lookup at path #{path}"
      raise Puppet::Error, append_api_errors(message, secret_response)
    end

    begin
      data = JSON.parse(secret_response.body)['data']
    rescue StandardError
      raise Puppet::Error, 'Error parsing json secret data from vault response'
    end

    if key.nil?
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(data)
    else
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(data[key])
    end
  end

  private

  def create_ssl_context(verify_ssl)
    ssl_provider = Puppet::SSL::SSLProvider.new
    default_ssl_context = ssl_provider.load_context

    ssl_context = Puppet::SSL::SSLContext.new(
      store: default_ssl_context.store,
      cacerts: default_ssl_context.cacerts,
      crls: default_ssl_context.crls,
      private_key: default_ssl_context.private_key,
      client_cert: default_ssl_context.client_cert,
      client_chain: default_ssl_context.client_chain,
      revocation: default_ssl_context.revocation,
      verify_peer: verify_ssl,
    )

    ssl_context
  end

  def get_auth_token(connection)
    response = connection.post('/v1/auth/cert/login', '')
    unless response.is_a?(Net::HTTPOK)
      message = "Received #{response.code} response code from vault at #{connection.address} for authentication"
      raise Puppet::Error, append_api_errors(message, response)
    end

    begin
      token = JSON.parse(response.body)['auth']['client_token']
    rescue StandardError
      raise Puppet::Error, 'Unable to parse client_token from vault response'
    end

    raise Puppet::Error, 'No client_token found' if token.nil?

    token
  end

  def get_local_auth_token(path)
    begin
      token = Puppet::FileSystem.read(path)
    rescue
      raise Puppet::Error, "Unable to read #{path}"
    end

    raise Puppet::Error, 'No client_token found' if token.nil?

    token
  end

  def append_api_errors(message, response)
    errors   = json_parse(response, 'errors')
    warnings = json_parse(response, 'warnings')
    message << " (api errors: #{errors})" if errors
    message << " (api warnings: #{warnings})" if warnings
    message
  end

  def json_parse(response, field)
    JSON.parse(response.body)[field]
  rescue StandardError
    nil
  end
end
