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
define users::account (
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $fullname = undef,
  Optional[String] $passwd = undef,
  Stdlib::Absolutepath $homedir = "/home/${title}",
  String $sudo = 'ALL=(ALL) ALL',
) {
  user { $name:
    ensure     => $ensure,
    comment    => $fullname,
    home       => $homedir,
    managehome => true,
    shell      => '/bin/bash',
    password   => $passwd,
  }

  if $ensure == 'present' {
    file { $homedir:
      ensure => directory,
      owner  => $name,
      group  => $name,
      mode   => '0755',
    }

    file { "${homedir}/.ssh":
      ensure => directory,
      owner  => $name,
      group  => $name,
      mode   => '0700',
    }

    file { "${homedir}/.ssh/authorized_keys":
      ensure  => file,
      content => file("${module_name}/${name}-authorized_keys"),
      owner   => $name,
      group   => $name,
      mode    => '0600',
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
