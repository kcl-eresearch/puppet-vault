# Vault icinga checks
class vault::icinga {
  ensure_packages(['python3-hvac'])

  file {
    '/usr/lib/nagios/plugins/check_vault':
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      source => 'puppet:///modules/role/vault/check_vault.py';
  }

  base::extensions::icinga::checkcommand {
    'vault':
      command => 'vault',
      require => File['/usr/lib/nagios/plugins/check_vault'];
  }

  if $facts['icinga_zone'] {
    @@role::icinga_server::service {
      "vault_${hostname}":
        service        => "vault_${hostname}",
        display_name   => 'Vault Status',
        check_command  => 'vault',
        run_on_client  => true,
        check_interval => '10m',
        host           => $fqdn,
        zone           => $facts['icinga_zone'],
        notify_slack   => true;
    }
  }
}
