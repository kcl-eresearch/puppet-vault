require File.dirname(__FILE__) + '/../puppet/common/vault'

Facter.add('vault_entity_id') do
  confine { Facter.value('vault_client') == True }
  setcode do
    unless File.file?('/root/.vault-entity-id')
      entityid = Vault::Client.new.connection_entityid
      File.open('/root/.vault-entity-id', 'w') { |f| f.write entityid.to_s }
    end

    File.read('/root/.vault-entity-id')
  end
end
