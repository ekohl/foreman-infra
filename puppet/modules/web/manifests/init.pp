# $stable::   latest release that users expect
# $next::     Next release (current nightly). To be updated as part of branching.
#
# $htpasswds:: Which htpasswds to create.
#
# All vhosts can be protected by a single SSL cert with additional names added in the certonly
# $domains parameter below.
#
# $https:: to request an LE cert via webroot mode, the HTTP vhost must be up.  To start httpd, the
#          certs have to exist, so keep SSL vhosts disabled until the certs are present via the HTTP
#          vhost and only then enable the SSL vhosts.
#
# $setup_receiver:: Set up the SSH receiver setup. Mostly turned off for testing.
#
class web(
  String $stable = '1.24',
  String $next = '2.1',
  Hash[String, Hash] $htpasswds = {},
  Boolean $https = false,
  Boolean $setup_receiver = true,
) {
  include web::base
  include rsync::server

  letsencrypt::certonly { 'theforeman.org':
    plugin        => 'webroot',
    # domain / webroot_paths must match exactly
    domains       => [
      'theforeman.org',
      'deb.theforeman.org',
      'debugs.theforeman.org',
      'downloads.theforeman.org',
      'stagingdeb.theforeman.org',
      'www.theforeman.org',
      'yum.theforeman.org',
      'docs.theforeman.org',
    ],
    webroot_paths => [
      '/var/www/vhosts/web/htdocs',
      '/var/www/vhosts/deb/htdocs',
      '/var/www/vhosts/debugs/htdocs',
      '/var/www/vhosts/downloads/htdocs',
      '/var/www/vhosts/stagingdeb/htdocs',
      '/var/www/vhosts/web/htdocs',
      '/var/www/vhosts/yum/htdocs',
      '/var/www/vhosts/docs/htdocs',
    ],
  }

  if $::selinux {
    include selinux

    # Use a non-HTTP specific context to be shared with rsync
    selinux::fcontext { 'fcontext-www':
      seltype  => 'public_content_t',
      pathspec => '/var/www(/.*)?',
    }
  }

  # maximum connection per rsync target
  # using a small value to try and reduce server load
  $max_rsync_connections = 5

  # WWW
  if $setup_receiver {
    secure_ssh::rsync::receiver_setup { 'web':
      user           => 'website',
      foreman_search => 'host ~ slave*.rackspace.theforeman.org and (name = external_ip4 or name = external_ip6)',
      script_content => file('web/rsync.sh'),
    }
  }
  $web_attrs = {
    servername      => 'theforeman.org',
    serveraliases   => ['www.theforeman.org'],
    docroot         => '/var/www/vhosts/web/htdocs',
    docroot_owner   => 'website',
    docroot_group   => 'website',
    docroot_mode    => '0755',
    custom_fragment => template('web/web.conf.erb'),
  }

  # DEBUGS
  $debugs_attrs = {
    servername      => 'debugs.theforeman.org',
    docroot         => '/var/www/vhosts/debugs/htdocs',
    docroot_owner   => 'nobody',
    docroot_group   => 'nobody',
    docroot_mode    => '0755',
    custom_fragment => template('web/debugs.conf.erb'),
  }
  # takes a hash like: { 'user' => { 'vhost' => 'debugs', passwd => 'secret' }
  create_resources(web::htpasswd, $htpasswds)

  # YUM
  $yum_directory = '/var/www/vhosts/yum/htdocs'
  $yum_directory_config = [
    {
      path            => $yum_directory,
      options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
    {
      path            => '.+\.(bz2|gz|rpm|xz)$',
      provider        => 'filesmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
    {
      path            => 'repomd.xml',
      provider        => 'files',
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
  ]

  $yum_attrs = {
    servername   => 'yum.theforeman.org',
    docroot      => $yum_directory,
    docroot_mode => '2575',
    directories  => $yum_directory_config,
  }

  rsync::server::module { 'yum':
    path            => '/var/www/vhosts/yum/htdocs',
    list            => true,
    read_only       => true,
    comment         => 'yum.theforeman.org',
    uid             => 'nobody',
    gid             => 'nobody',
    max_connections => $max_rsync_connections,
  }

  # DOCS
  $docs_directory = '/var/www/vhosts/docs/htdocs'
  $docs_directory_config = [
    {
      path    => $docs_directory,
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    },
  ]

  $docs_attrs = {
    servername    => 'docs.theforeman.org',
    docroot       => $docs_directory,
    directories   => $docs_directory_config,
    docroot_owner => 'website',
    docroot_group => 'website',
    docroot_mode  => '0755',
  }

  if $::osfamily == 'RedHat' {
    package { 'createrepo':
      ensure => present,
    }
  }

  file { '/var/www/vhosts/yum/htdocs/HEADER.html':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/web/yum-HEADER.html',
  }
  file { '/var/www/vhosts/yum/htdocs/robots.txt':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/web/yum-robots.txt',
  }
  file { '/var/www/vhosts/yum/htdocs/RPM-GPG-KEY-foreman':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/web/RPM-GPG-KEY-foreman',
  }
  file { '/var/www/vhosts/yum/htdocs/releases':
    ensure => directory,
  }
  file { '/var/www/vhosts/yum/htdocs/releases/latest':
    ensure => link,
    target => $stable,
  }
  file { '/var/www/vhosts/yum/htdocs/releases/nightly':
    ensure => link,
    target => '../nightly',
  }
  file { '/var/www/vhosts/yum/htdocs/plugins/latest':
    ensure => link,
    target => $stable,
  }
  file { '/var/www/vhosts/yum/htdocs/client/latest':
    ensure => link,
    target => $stable,
  }
  file { '/var/www/vhosts/yum/htdocs/rails/latest':
    ensure => link,
    target => "foreman-${stable}",
  }

  # DOWNLOADS
  $downloads_directory = '/var/www/vhosts/downloads/htdocs'
  $downloads_directory_config = [
    {
      path    => $downloads_directory,
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    },
    {
      path            => '.+\.(bz2|csv|gem|gz|img|iso|iso-img|iso-vmlinuz|pdf|tar|webm|rpm|deb)$',
      provider        => 'filesmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
  ]

  $downloads_attrs = {
    servername   => 'downloads.theforeman.org',
    docroot      => $downloads_directory,
    docroot_mode => '2575',
    directories  => $downloads_directory_config,
  }
  rsync::server::module { 'downloads':
    path            => $downloads_directory,
    list            => true,
    read_only       => true,
    comment         => 'downloads.theforeman.org',
    uid             => 'nobody',
    gid             => 'nobody',
    max_connections => $max_rsync_connections,
  }
  file { "${downloads_directory}/HEADER.html":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/web/downloads-HEADER.html',
  }

  # Create the vhosts defined above
  create_resources(
    'apache::vhost',
    {
      'debugs'    => $debugs_attrs,
      'downloads' => $downloads_attrs,
      'web'       => $web_attrs,
      'yum'       => $yum_attrs,
      'docs'       => $docs_attrs,
    },
    {
      'port'      => '80',
    }
  )

  if $https {
    create_resources(
      'apache::vhost',
      {
        'debugs-https'    => $debugs_attrs,
        'downloads-https' => $downloads_attrs,
        'web-https'       => $web_attrs,
        'yum-https'       => $yum_attrs,
        'docs-https'       => $docs_attrs,
      },
      {
        'port'      => '443',
        'ssl'       => true,
        'ssl_cert'  => '/etc/letsencrypt/live/theforeman.org/fullchain.pem',
        'ssl_chain' => '/etc/letsencrypt/live/theforeman.org/chain.pem',
        'ssl_key'   => '/etc/letsencrypt/live/theforeman.org/privkey.pem',
        'require'   => Letsencrypt::Certonly['theforeman.org'],
      }
    )
  }

  # METRICS
  # script to do initial filtering of apache logs for download metrics
  file { '/usr/local/bin/filter_apache_stats':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0744',
    source => 'puppet:///modules/web/filter_apache_stats.sh',
  }

  # daily at 4am, should be fairly quiet on the server
  cron { 'filter_apache_stats':
    command => '/usr/bin/nice -19 /usr/local/bin/filter_apache_stats',
    user    => root,
    hour    => '4',
    minute  => '0',
  }
}
