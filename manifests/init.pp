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
package { 'mysql-server': 	ensure => 'latest', }
package { 'libmysqlclient-dev': 	ensure => 'latest', }
package { 'redis-server': 	ensure => 'latest', }
package { 'openssl': 	ensure => 'latest', }


vcsrepo { '/opt/hashview':
	ensure => present,
	provider => git,
	source => 'https://github.com/hashview/hashview.git',
}

exec { 'bundle-test':
	command => "bundle install",
	cwd => '/opt/hashview',
	path => ['/usr/local/rvm/gems/ruby-2.2.2@hashview/wrappers', '/usr/bin', '/usr/bash', '/bin'],
	user => 'ubuntu',
}
}
