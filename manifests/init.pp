class named (
		$upstreamresolver=undef,
		$resolver=true,
		$keysdir="${named::params::confdir}/keys",
		$alsonotify=undef,
		$dnssecenable ="no",
		$dnssecvalidation="no",
		$controls=undef, #TODO: rewrite
		$ensure='installed',
		) inherits params {

	if defined(Class['ntteam'])
	{
		ntteam::tag{ 'named': }
	}

	if ($upstreamresolver) {
		validate_array($upstreamresolver)
	}

	validate_bool($resolver)

	if ($alsonotify)
	{
		validate_array($alsonotify)
	}

	if ($controls)
	{
		validate_array($controls)
	}

	validate_re($ensure, [ '^installed$', '^latest$' ], "Not a valid package status: ${package_status}")

	if defined(Class['netbackupclient'])
	{
		netbackupclient::includedir{ '/var/named': }

	}

	#deprecated, crec
	#include concat::setup

	package { $named::params::packages:
		ensure => $ensure,
	}

	file { "${keysdir}":
		ensure => directory,
		owner => "root",
		group => $named::params::osuser,
		mode => 0750,
		require => Package[$named::params::packages],
	}

	$keysdishelpers="${keysdir}/.helpers"
	file { $keysdishelpers:
		ensure => directory,
		owner => "root",
		group => $named::params::osuser,
		require => File[$keysdir],
		mode => 0750,

	}

	concat { $named::params::options_file:
		ensure => present,
		owner => "root",
		group => $named::params::osuser,
		mode => 0640,
		require => Package[$named::params::packages],
		notify  => Service[$named::params::servicename],
	}

	if($localconfig_file==$options_file)
	{
		concat::fragment{ "$named::params::options_file tail":
			target  => $named::params::options_file,
			content => template("named/namedRH.erb"),
			order   => '99',
		}

	}
	else
	{
		concat { $named::params::localconfig_file:
			ensure => present,
			owner => "root",
			group => $named::params::osuser,
			mode => 0640,
			require => Package[$named::params::packages],
			notify  => Service[$named::params::servicename],
		}

		concat::fragment{ "$named::params::localconfig_file header":
			target  => $named::params::localconfig_file,
			content => "//\n// Puppet managed - do not edit\n//\n\n",
			order   => '01',
		}

	}

	concat::fragment{ "$named::params::localconfig_file localconf content":
		target  => $named::params::localconfig_file,
		content => template("named/namedlocalconf.erb"),
		order   => '50',
	}

	concat::fragment{ "$named::params::options_file header":
		target  => $named::params::options_file,
		content => "//\n// Puppet managed - do not edit\n//\n\n",
		order   => '01'
	}

	concat::fragment{ "$named::params::options_file options content":
		target  => $named::params::options_file,
		content => template("named/namedoptions.erb"),
		order   => '02'
	}



	file { $named::params::directory:
		ensure => directory,
		owner => "root",
		group => $named::params::osuser,
		mode => 0770,
		require => Package[$named::params::packages],
	}

	file { "${named::params::directory}/data":
		ensure => directory,
		owner => $named::params::osuser,
		group => $named::params::osuser,
		mode => 0770,
		require => File[$named::params::directory],
	}

	file { "${named::params::confdir}":
		ensure => directory,
		owner => "root",
		group => $named::params::osuser,
		mode => 0770,
		require => File[ [$named::params::directory, "${named::params::directory}/data" ] ],
	}

	concat { "${named::params::confdir}/puppet-managed.zones":
		ensure => present,
		owner => "root",
		group => $named::params::osuser,
		mode => 0640,
		require => File[$named::params::confdir],
		notify  => Service[$named::params::servicename],
	}

	concat { "${named::params::confdir}/puppet-managed.keys":
		ensure => present,
		owner => "root",
		group => $named::params::osuser,
		mode => 0640,
		require => File[$named::params::confdir],
		notify  => Service[$named::params::servicename],
	}

	concat::fragment{ 'puppet_header_zones':
		target  => "${named::params::confdir}/puppet-managed.zones",
		content => "//\n// Puppet managed - do not edit\n//\n\n",
		order   => '01'
	}

	concat::fragment{ 'puppet_header_keys':
		target  => "${named::params::confdir}/puppet-managed.keys",
		content => "//\n// Puppet managed - do not edit\n//\n\n",
		order   => '01'
	}

	service { $named::params::servicename:
		enable => true,
		ensure => "running",
		require => Concat["${named::params::confdir}/puppet-managed.zones"],
	}

}
