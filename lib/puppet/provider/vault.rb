# frozen_string_literal: true

require File.dirname(__FILE__) + '/../common/vault'

# Puppet provider for vault
class Puppet::Provider::Vault < Puppet::Provider
  initvars
  ENV['PATH'] = ENV['PATH'] + ':/usr/libexec:/usr/local/libexec:/usr/local/bin'
  commands vault_cmd: 'vault'

  def self.vault_caller(command, namespace = nil)
    vault = "vault #{command} -tls-skip-verify"
    vault += " -namespace=#{namespace}" if namespace
    res = `#{vault}`
    res
  end
end
