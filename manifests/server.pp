class vault::server
{
  apt::source {
    'hashicorp':
      location => 'https://apt.releases.hashicorp.com',
      repos    => 'main',
      key      => {
        'id'     => 'E8A032E094D8EB4EA189D270DA418C88A3219F7B',
        'source' => 'https://apt.releases.hashicorp.com/gpg',
      },
  }

  package {
    'vault':
      require => Apt::Source['hashicorp'];
  }

  service {
    'vault':
      ensure => 'running',
      enable => true;
  }

  # Add role to the MOTD.
  concat::fragment { 'motd_role_vault':
    target  => '/etc/motd',
    order   => 20,
    content => '    -- Vault server\n'
  }
}
