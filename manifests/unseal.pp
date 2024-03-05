class vault::unseal {
  file {
    '/usr/local/sbin/vault_unseal':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => file('vault/vault_unseal.py');

    '/etc/vault_unseal':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0550';
  }
}
