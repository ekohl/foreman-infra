# @summary A Jenkins node
#
# @param koji_certificate
#   An optional koji certificate for trusted nodes. Only relevant on Red Hat
#   based machines.
#
# @param swap_size_mb
#   The swap file size in MBs. Will be unmanaged if set to 0
#
# @param unittests
#   Should the node be able to run unittests
#
# @param packaging
#   Should the node be able to run packaging jobs
class profiles::jenkins::node (
  Optional[String[1]] $koji_certificate = undef,
  Integer[0] $swap_size_mb = 8192,
  Boolean $unittests = $facts['os']['family'] == 'RedHat',
  Boolean $packaging = true,
) {
  class { 'slave':
    koji_certificate    => $koji_certificate,
    unittests           => $unittests,
    packaging           => $packaging,
    ssh_authorized_keys => [
      {
        'type'    => 'ssh-rsa',
        'key'     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQD0QacqcRQzycs7r6odx94FqSEme3O8q/IQAu8A4GTxGzUpsUKQtvE9gzi0TrYZbyzYCMD+MTmDXmk+wPB+QaaHdJhSLe+Tu4tPgX5cp3u6RnrDXVfMg8BTK5kUPcgQJ9QIOMH03weLHw7G5ZC6YCDQz0iRhofJ6ZAFle2aHTg6emjUIxG0Ox4oHhX8cqozcCm/TI3ZspBiUgJo6oaWwkDHcnzi453j5jaxOLD2ykI8+dO6F1Strk1+DnbbnD91PAZuHG9Jg3C1naGdGOYLJ5rfIRLxDkGHXLEwpS7s1lti+p4zNWpcLa5lspEVmdPrEzxmyRNul+/WR/STjKbTtCWt',
        'comment' => 'master02.rackspace.theforeman.org',
      },
    ],
  }

  if $swap_size_mb > 0 {
    class { 'slave::swap':
      size_mb => $swap_size_mb,
    }
  }

  # Ensure REX can log in
  class { 'foreman_proxy::plugin::remote_execution::ssh_user':
    manage_user => true,
  }
}
