class hashview (
  $port = $hashview::params::port,
  $db_password = $hashview::params::db_password,
  $hostname = $hashview::params::hostname,
  $hashcat_install_path = $hashview::params::hashcat_install_path,
  $hashview_install_path = $hashview::params::hashview_install_path,
) inherits hashview::params {
tag 'hashview'
include 'hashcat'

#package { 'ruby': ensure => 'latest', }
#package { 'rubygems': ensure => 'latest', }

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
#package { 'mysql-server': 	ensure => 'latest', }

package { 'libmysqlclient-dev': 	ensure => 'latest', }
package { 'redis-server': 	ensure => 'latest', }
package { 'openssl': 	ensure => 'latest', }

class { '::mysql::server':
  root_password           => $db_password,
  remove_default_accounts => true,
  override_options        => $override_options
}

file { $hashview_install_path:
	ensure => 'directory',
	owner  => 'ubuntu',
	group  => 'ubuntu',
  mode   => '0770',
}

vcsrepo { "${hashview_install_path}/hashview":
	ensure => present,
	provider => git,
	source => 'https://github.com/hashview/hashview.git',
	user => 'ubuntu',
	owner => 'ubuntu',
	group => 'ubuntu',
}

file { "${hashview_install_path}/hashview/Procfile":
	ensure => file,
	content => @(END/L),
		mgmt-worker: TERM_CHILD=1 COUNT=5 QUEUE=management rake resque:workers
		hashcat-worker: TERM_CHILD=1 COUNT=1 QUEUE=hashcat rake resque:work
		background-worker: QUEUE=* rake resque:scheduler
		web: ruby ./hashview.rb
		| END
}

exec { 'bundle-install':
	command => "bundle install",
	cwd => "${hashview_install_path}/hashview",
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

exec { 'copy-hashview-config':
	command => "cp config/database.yml.example config/database.yml",
	cwd => "${hashview_install_path}/hashview",
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

yaml_setting { 'set_db_password':
  target => "${hashview_install_path}/hashview/config/database.yml",
  key => 'production/password',
  value => $db_password,
}

exec { 'bundle-exec':
	environment => ["RACK_ENV=production"],
	command => "bundle exec rake db:migrate || bundle exec rake db:setup",
	cwd => "${hashview_install_path}/hashview",
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}

#exec { 'foreman-start':
#	environment => ["RACK_ENV=production", "TZ=Europe/Oslo"],
#	command => "foreman start",
#	cwd => "${hashview_install_path}/hashview",
#	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
#	user => 'ubuntu',
#}

}
