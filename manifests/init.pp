class hashview (
					$port = $hashview::params::port,
					$db_password = $hashview::params::db_password,
					$hostname = $hashview::params::hostname,
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
				package { 'libmysqlclient-dev': 	ensure => 'latest', }
				package { 'openssl': 	ensure => 'latest', }

				class { '::mysql::server':
					root_password           => $db_password,
					remove_default_accounts => true,
					override_options        => $override_options
				}

				class { '::redis':
					bind => '127.0.0.1',
					service_enable => false,
					#service_hasstatus => false,
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
					source => 'puppet:///modules/hashview/Procfile',
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

				augeas { "hashview-config":
					incl => "${hashview_install_path}/hashview/config/agent_config.travis.json",
					lens => "Json.lns",
					#context => "/files${hashview_install_path}/hashview/config/agent_config.travis.json",
					changes => ["set dict/entry[*][.=\"ip\"]/string \"${hostname}\"",
							"set dict/entry[*][.=\"port\"]/string \"${port}\"",
							"set dict/entry[*][.=\"hc_binary_path\"]/string \"/opt/hashcat/hashcat64.bin\""]
				}

				exec { 'bundle-exec':
					environment => ["RACK_ENV=production"],
					command => "bundle exec rake db:migrate || bundle exec rake db:setup",
					cwd => "${hashview_install_path}/hashview",
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
}
