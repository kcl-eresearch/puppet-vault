
Puppet::Type.newtype(:vault_policy) do
  @doc = 'Create a vault policy.'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The name of the policy.'
  end

  newproperty(:content) do
    desc 'The policy content (HCL format).'

    validate do |value|
      raise ArgumentError, _('Content must be a String') unless value.is_a?(String)
    end
  end
end
