
Puppet::Type.newtype(:vault_group) do
  @doc = 'Create a new vault group.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the new group.'
  end

  newproperty(:policies) do
    desc 'The policies for the group.'
  end
end
