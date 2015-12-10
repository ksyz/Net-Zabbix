use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME			=> 'Net::Zabbix',
	VERSION_FROM	=> 'lib/Net/Zabbix.pm',
	AUTHOR			=> 'Michal Ingeli <mi@v3.sk>',
	LICENSE			=> 'WTF-PL',
	PREREQ_PM		=> {
		'LWP'		=> 0,
		'LWP::Protocol::https'	=> 0,
		'Net::SSL'	=> 0,
		'Net::DNS'	=> 0, # for examples
		'Net::IP'	=> 0, # for examples
		'Net::SNMP' => 0, # for examples
		'JSON::PP'	=> 0,
		'Scalar::Util'	=> 0,
		'Carp'		=> 0,
		'Time::HiRes'	=> 0,
		'POSIX'		=> 0,
	},
);
