class vault::server (
  Boolean $motd = true,
  Array[Hash] $listeners = [
    {
      'type'              => 'tcp',
      'address'           => '0.0.0.0:8200',
      'tls_disable'       => false,
      'tls_cert_file'     => '/opt/vault/tls/tls.crt',
      'tls_key_file'      => '/opt/vault/tls/tls.key',
      'tls_min_version'   => 'tls12',
      'tls_max_version'   => 'tls13',
      'tls_cipher_suites' => [
        'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256',
        'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256',
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
      ],
    },
  ],
  Hash $storage_config = {
    'file' => {
      'path' => '/opt/vault/data'
    },
  },
  Boolean $ui_enabled = true,
  Boolean $disable_mlock = true,
) {
  apt::source {
    'hashicorp':
      location => 'https://apt.releases.hashicorp.com',
      repos    => 'main',
      key      => {
        'id'      => '798AEC654E5C15428C8E42EEAA16FCBCA621E701',
        'source'  => 'https://apt.releases.hashicorp.com/gpg',
        'options' => sprintf('http-proxy="http://%s:%d"', lookup('global::http_proxy_host'), lookup('global::http_proxy_port'))
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

  if $motd {
    # Add role to the MOTD.
    concat::fragment { 'motd_role_vault':
      target  => '/etc/motd',
      order   => '50',
      content => '    -- Vault server',
    }
  }

  file {
    '/var/log/vault':
      ensure  => 'directory',
      owner   => 'vault',
      group   => 'vault',
      mode    => '0700',
      require => Package['vault'];
  }

  file { '/etc/vault.d/vault.hcl':
    ensure  => file,
    content => epp('vault/server/vault.hcl.epp', {
      'listeners'         => $listeners,
      'storage_config'    => $storage_config,
      'tls_min_version'   => $tls_min_version,
      'tls_max_version'   => $tls_max_version,
      'tls_cipher_suites' => $tls_cipher_suites,
      'ui_enabled'        => $ui_enabled,
      'disable_mlock'     => $disable_mlock,
    }),
    owner   => 'vault',
    group   => 'vault',
    mode    => '0640',
    require => Package['vault'],
    notify  => Service['vault'];
  }
}
