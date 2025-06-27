class vault::server (
  Enum['openbao', 'vault'] $package = 'vault',
  Boolean $motd = true,
  Array[Hash] $listeners = [
    {
      'type'          => 'tcp',
      'address'       => '0.0.0.0:8200',
      'tls_disable'   => false,
      'tls_cert_file' => '/opt/vault/tls/tls.crt',
      'tls_key_file'  => '/opt/vault/tls/tls.key',
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
  $tls_max_version = 'tls13'
  $tls_min_version = 'tls12'
  $tls_cipher_suites = [
    'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256',
    'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
  ]

  if $package == 'vault' {
    $owner = $package
    $config_file = '/etc/vault.d/vault.hcl'
    $config = epp('vault/server/vault.hcl.epp', {
      'listeners'         => $listeners,
      'storage_config'    => $storage_config,
      'tls_min_version'   => $tls_min_version,
      'tls_max_version'   => $tls_max_version,
      'tls_cipher_suites' => $tls_cipher_suites,
      'ui_enabled'        => $ui_enabled,
      'disable_mlock'     => $disable_mlock,
    })

    apt::source { 'hashicorp':
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
    file { "/var/log/${package}":
      ensure => 'directory',
      owner  => $owner,
      group  => $owner,
      mode   => '0700',
    }
  }
  else {
    $owner = 'openbao'
    $config_file = '/etc/openbao/openbao.json'
    # if tls_disable is set to false then use hardened tls settings
    $final_listeners = $listeners.map |$listener| { if !$listener['tls_disable'] {
      $listener + {
        'tls_cipher_suites' => $tls_cipher_suites.join(','),
        'tls_max_version'   => $tls_max_version,
        'tls_min_version'   => $tls_min_version,
      } } else { $listener }}

    $config = to_json_pretty({
      'listener'         => $final_listeners,
      'storage'          => $storage_config,
      'ui'               => $ui_enabled,
    })
    # Use package from er mirrors
    package {
        'bao':
    }

    file { '/etc/profile.d/100-openbao-env.sh':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => "
        export BAO_CLIENT_CERT=${settings::ssldir}/certs/${trusted['certname']}.pem
        export BAO_CACERT=${settings::ssldir}/certs/ca.pem
        export BAO_CLIENT_KEY=${settings::ssldir}/private_keys/${trusted['certname']}.pem
        export BAO_ADDR=https://${trusted['certname']}:8200
      ";
    }

    systemd::manage_unit { 'openbao.service':
      ensure        => 'present',
      enable        => true,
      active        => true,
      unit_entry    => {
        'Description' => 'OpenBao - A tool for managing secrets',
        'After'       => 'network.target',
      },
      service_entry => {
        'Type'                       => 'notify',
        'ExecStart'                  => 'bao server -config $CONFIGURATION_DIRECTORY',
        'ExecReload'                 => '/bin/kill -SIGHUP $MAINPID',
        'Restart'                    => 'on-failure',
        'StateDirectory'             => 'openbao',
        'RuntimeDirectory'           => 'openbao',
        'ConfigurationDirectory'     => 'openbao',
        'ConfigurationDirectoryMode' => '0750',
        'LogsDirectory'              => 'openbao',
        'RuntimeDirectoryMode'       => '0700',
        # Load Puppet certificates to be available to the service at /run/credentials/openbao.service/$NAME
        'LoadCredential'             =>  [
            "puppet-cert:${settings::ssldir}/certs/${trusted['certname']}.pem",
            "puppet-key:${settings::ssldir}/private_keys/${trusted['certname']}.pem",
            "puppet-ca:${settings::ssldir}/certs/ca.pem",
        ],
        'Environment'                => 'Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        'DynamicUser'                => true,
        'CapabilityBoundingSet'      => 'CAP_SYSLOG',
        'NoNewPrivileges'            => true,
        'LimitCORE'                  => '0',
        'LockPersonality'            => true,
        # Disasble Swap
        # https://openbao.org/docs/rfcs/mlock-removal/
        'MemorySwapMax'              => '0',
        'PrivateUsers'               => true,
        'PrivateTmp'                 => true,
        'ProtectClock'               => true,
        'ProtectControlGroups'       => true,
        'ProtectHome'                => true,
        'ProtectHostname'            => true,
        'ProtectKernelLogs'          => true,
        'ProtectKernelModules'       => true,
        'ProtectKernelTunables'      => true,
        'ProtectProc'                => 'invisible',
        'RestrictAddressFamilies'    => ['AF_INET', 'AF_INET6', 'AF_UNIX'],
        'RestrictNamespaces'         => true,
        'RestrictRealtime'           => true,
        'SystemCallArchitectures'    => 'native',
        'SystemCallFilter'           => ['@system-service', '@resources', '~@privileged'],
        'SecureBits'                 => 'keep-caps',
        'UMask'                      => '0077',
      },
      install_entry => {
        'WantedBy' => 'multi-user.target',
      },
      require       => [
        Package['bao'],
      ],
    }
  }

  if $motd {
    # Add role to the MOTD.
    concat::fragment { "motd_role_${package}":
      target  => '/etc/motd',
      order   => '50',
      content => "    -- ${package} server",
    }
  }

  service {
    $package:
        ensure  => 'running',
        enable  => true,
        restart => "/usr/bin/systemctl reload ${package}";
  }

  file { $config_file:
    ensure  => file,
    content => $config,
    owner   => $owner,
    group   => $owner,
    mode    => '0640',
    notify  => Service[$package];
  }
}
