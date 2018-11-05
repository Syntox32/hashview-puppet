class hashview (
  $port = $hashview::params::port,
  $hostname = $hashview::params::hostname,
  $hashcat_install_path = $hashview::params::hashcat_install_path,
  $hashview_install_path = $hashview::params::hashview_install_path,
) inherits hashview::params {
tag 'hashview'
include 'hashcat'

class { '::rvm': }
#rvm::system_user { ubuntu: ; }

rvm_system_ruby {
	'ruby-2.2.2':
		ensure => 'present',
		default_use => true,
}

rvm_gemset {
	'ruby-2.2.2@hashview':
		ensure => present,
		require => Rvm_system_ruby['ruby-2.2.2'];
}

rvm_gem {
  'ruby-2.2.2@hashview/bundler':
    ensure  => 'latest',
    require => Rvm_gemset['ruby-2.2.2@hashview'];
}

package { 'git': 	ensure => 'latest', }
package { 'ruby': 	ensure => 'latest', }
package { 'rubygems': 	ensure => 'latest', }
package { 'ruby-bundler': 	ensure => 'latest', }
package { 'libmysqlclient-dev': 	ensure => 'latest', }
package { 'openssl': 	ensure => 'latest', }

class { '::mysql::server':
  root_password           => 'CHANGEME',
  remove_default_accounts => true,
  override_options        => $override_options
}

class { '::redis':
	bind => '127.0.0.1',
	service_enable => false,
	#service_hasstatus => false,
}

file { '/opt/hashview':
	ensure => 'directory',
	owner  => 'ubuntu',
	group  => 'ubuntu',
  mode   => '0770',
}

vcsrepo { '/opt/hashview/hashview':
	ensure => present,
	provider => git,
	source => 'https://github.com/hashview/hashview.git',
	user => 'ubuntu',
	owner => 'ubuntu',
	group => 'ubuntu',
}

file { '/opt/hashview/hashview/Procfile':
	source => 'puppet:///modules/hashview/Procfile',
}

exec { 'bundle-install':
	command => "bundle install",
	cwd => '/opt/hashview/hashview',
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

exec { 'copy-hashview-config':
	command => "cp config/database.yml.example config/database.yml",
	cwd => '/opt/hashview/hashview',
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

exec { 'bundle-exec':
	environment => ["RACK_ENV=production"],
	command => "bundle exec rake db:migrate || bundle exec rake db:setup",
	cwd => '/opt/hashview/hashview',
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

file { '/etc/systemd/system/hashview.service':
	source => 'puppet:///modules/hashview/hashview.service',
	notify => Service['hashview'],
}

service { 'hashview':
	ensure => running,
}

#exec { 'foreman-start':
#	environment => ["RACK_ENV=production", "TZ=Europe/Oslo"],
#	command => "foreman start",
#	cwd => '/opt/hashview/hashview',
#	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
#	user => 'ubuntu',
#}

}
