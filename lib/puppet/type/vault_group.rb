
Puppet::Type.newtype(:vault_group) do
  @doc = 'Create a new vault group.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the new group.'
  end

  newparam(:namespace) do
    desc 'The Vault namespace to use.'
  end

  newparam(:mount) do
    desc 'The Vault auth mount path.'
    defaultto '/v1/auth/cert/login'
  end

  newproperty(:policies) do
    desc 'The policies for the group.'
  end
end
