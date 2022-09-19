# @summary Manage a user account
#
# @param ensure
#   The state of the user to ensure
# @param fullname
#   The full name of the user
# @param passwd
#   The password hash
# @param homedir
#   The home directory
# @param sudo
#   The sudo line to ensure. Set to an empty string to disallow sudo
# @param ssh_authorized_keys
#   The SSH authorized keys to allow. Any unmanaged keys are purged.
define users::account (
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $fullname = undef,
  Optional[String] $passwd = undef,
  Stdlib::Absolutepath $homedir = "/home/${title}",
  String $sudo = 'ALL=(ALL) ALL',
  Array[Users::Ssh_authorized_key] $ssh_authorized_keys = [],
) {
  user { $name:
    ensure         => $ensure,
    comment        => $fullname,
    home           => $homedir,
    managehome     => true,
    shell          => '/bin/bash',
    password       => $passwd,
    purge_ssh_keys => true,
  }

  if $ensure == 'present' {
    file { $homedir:
      ensure => directory,
      owner  => $name,
      group  => $name,
      mode   => '0755',
    }

    unless empty($ssh_authorized_keys) {
      file { "${homedir}/.ssh":
        ensure => directory,
        owner  => $name,
        group  => $name,
        mode   => '0700',
      }

      $ssh_authorized_keys.each |$index, $key| {
        $comment = $index ? {
          0       => $key['comment'],
          default => "${key['comment']} - ${index}",
        }

        ssh_authorized_key { $comment:
          key  => $key['key'],
          type => $key['type'],
          user => $name,
        }
      }
    }

    $sudo_ensure = bool2str($sudo == '', 'absent', 'present')
  } else {
    $sudo_ensure = $ensure
  }

  include sudo
  sudo::conf { "sudo-puppet-${name}":
    ensure  => $sudo_ensure,
    content => "${name} ${sudo}",
  }
}
