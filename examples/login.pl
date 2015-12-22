#!/usr/bin/perl
# this script will list hosts.

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Net::Zabbix;

my $z = Net::Zabbix->new(
	url =>"https://noc.ninja/zabbix/", 
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

