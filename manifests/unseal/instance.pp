define vault::unseal::instance (
  Enum['absent', 'present'] $ensure = 'present',
  Stdlib::Fqdn $vault_host = $title,
  Stdlib::Port $vault_port = 8200,
  Array[Hash] $unseal_portions,
) {

  include vault::unseal

  if $ensure == 'present' {
    file {
      "/etc/vault_unseal/${vault_host}.yaml":
        ensure    => 'file',
        owner     => 'root',
        group     => 'root',
        mode      => '0440',
        content   => to_yaml({
          'vault_host'      => $vault_host,
          'vault_port'      => $vault_port,
          'unseal_portions' => $unseal_portions,
        }),
        show_diff => false;
    }
  }

  cron {
    "Unseal Vault ${title}":
      ensure  => $ensure,
      user    => 'root',
      minute  => fqdn_rand(60, "Unseal Vault ${title}"),
      command => "/usr/local/sbin/vault_unseal ${vault_host}";
  }
}
