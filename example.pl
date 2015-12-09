#!/usr/bin/perl
#

use strict;
use warnings;

use lib "lib";

use Net::Zabbix;
use Data::Dumper;

my $z = Net::Zabbix->new(
	url =>"https://mon.in.o2bs.sk/zabbix/", 
	username => 'APIUser', 
	password => 'calvin',
	verify_ssl => 0,
	debug => 1,
	trace => 0,
);
$z->output(Net::Zabbix::OUTPUT_REFER);

print Dumper($z->get("host", { 
	output => Net::Zabbix::OUTPUT_EXTEND,
	selectItems => Net::Zabbix::OUTPUT_REFER,
	selectInterfaces => Net::Zabbix::OUTPUT_EXTEND,
	filter => { status => 0}
}));

