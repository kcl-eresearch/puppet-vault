# rubocop:disable Style/ClassAndModuleChildren
module Vault
  #
  # Vault client library.
  #
  class Client

    def initialize(url = nil, mount = '/v1/auth/cert/login')
      # fall back to using the local FQDN if no url is provided
      @uri = url || "https://vault.#{Facter.value('networking.domain')}:8200"
      Puppet.debug("Vault URL is: #{url}")
      Puppet.debug("Mount is #{mount}")

      @client = Puppet.runtime[:http]
      @token = ''
      @token = auth_token(mount)
    end

    def encode_path(path)
      raise ArgumentError, "'encode_path' requires a string 'path' argument" unless path.is_a?(String)
      URI.join(@uri, path)
    end

    def headers
      if @token == ''
        { 'Content-Type' => 'application/json' }
      else
        { 'X-Vault-Token' => @token + '', 'Content-Type' => 'application/json' }
      end
    end

    def connection_entityid
      data = get('/v1/auth/token/lookup-self')
      data['data']['entity_id']
    end

    def get(path)
      response = @client.get(encode_path(path), headers: headers, options: { include_system_store: true })
      unless response.success?
        message = "Received #{response.code} response code from vault for get at path #{path} (#{response.reason})"
        raise Puppet::Error, message
      end

      begin
        data = JSON.parse(response.body)
      rescue StandardError
        raise Puppet::Error, 'Error parsing json secret data from vault response'
      end

      data
    end

    def get_if_exists(path)
      response = @client.get(encode_path(path), headers: headers, options: { include_system_store: true })
      unless response.success?
        if response.code == 404
          return nil
        end
        message = "Received #{response.code} response code from vault for get at path #{path} (#{response.reason})"
        raise Puppet::Error, message
      end

      begin
        data = JSON.parse(response.body)
      rescue StandardError
        raise Puppet::Error, 'Error parsing json secret data from vault response'
      end

      data
    end

    def post(path, data = '')
      data = JSON.generate(data) unless data.is_a?(String)
      raise ArgumentError, "'post' requires a string 'data' argument" unless data.is_a?(String)
      response = @client.post(encode_path(path), data, headers: headers, options: { include_system_store: true })

      return nil if response.code == 204

      unless response.success?
        message = "Received #{response.code} response code from vault for post at path #{path} (#{response.reason})"

        Puppet.debug("Received Error: #{response.body} for post at path #{path}")
        raise Puppet::Error, message
      end

      begin
        data = JSON.parse(response.body)
      rescue StandardError
        raise Puppet::Error, 'Error parsing json secret data from vault response'
      end

      data
    end

    def put(path, data = '')
      data = JSON.generate(data) unless data.is_a?(String)
      raise ArgumentError, "'post' requires a string 'data' argument" unless data.is_a?(String)

      response = @client.put(encode_path(path), data, headers: headers, options: { include_system_store: true })
      raise Puppet::Error, "Received #{response.code} response code from vault for put at path #{path} (#{response.reason})" unless response.success?
    end

    def delete(path)
      response = @client.delete(encode_path(path), headers: headers, options: { include_system_store: true })
      raise Puppet::Error, "Received #{response.code} response code from vault for delete at path #{path} (#{response.reason})" unless response.success?
    end

    def entityid_from_fqdn(fqdn)
      # This is stupid, but vault gives us no mechanism for retrieving an alias by name.
      aliases = get('/v1/identity/entity-alias/id?list=true')
      aliases['data']['keys'].each do |key|
        aliasdata = get("/v1/identity/entity-alias/id/#{key}")
        if aliasdata['data']['name'] == fqdn
          return aliasdata['data']['canonical_id']
        end
      end

      nil
    end

    def get_policy(policy)
      pol = get("/v1/sys/policies/acl/#{policy}")
      pol['data']['policy']
    end

    def create_policy(name, content)
      put("/v1/sys/policies/acl/#{name}", 'policy' => content)
    end

    def delete_policy(name)
      delete("/v1/sys/policies/acl/#{name}")
    end

    def entity_policies(entityid)
      entity = get("/v1/identity/entity/id/#{entityid}")
      policies = entity['data']['policies']
      return [] if policies.nil?
      policies
    end

    def entity_add_policy(fqdn, policy)
      entity_add_policies(fqdn, [policy])
    end

    def entity_add_policies(fqdn, policies)
      entityid = entityid_from_fqdn(fqdn)
      return if entityid.nil?

      existing = entity_policies(entityid)
      newpolicies = existing + policies
      post("/v1/identity/entity/id/#{entityid}", 'policies' => policies) unless newpolicies.size == existing.size
    end

    def entity_remove_policy(fqdn, policy)
      entityid = entityid_from_fqdn(fqdn)
      return if entityid.nil?

      existing = entity_policies(entityid)
      newpolicies = existing - [policy]
      post("/v1/identity/entity/id/#{entityid}", 'policies' => policies) unless newpolicies.size == existing.size
    end

    private

    def auth_token(mount = '/v1/auth/cert/login')
      response = post(mount)
      token = response['auth']['client_token']

      raise Puppet::Error, 'No client_token found' if token.nil?

      token
    end
  end
end
