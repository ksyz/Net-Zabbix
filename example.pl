#!/usr/bin/perl
#

use strict;
use warnings;

use lib "lib";

use Net::Zabbix;
use Data::Dumper;

my $z = Net::Zabbix->new("http://localhost/zabbix/", "_api", "orion", 1);

$z->{Output} = Net::Zabbix::OUTPUT_REFER;

print Dumper($z->get("host", { 
	selectItems => Net::Zabbix::OUTPUT_REFER,
	# filter => { status => 0}
}));

print Dumper($z->get("trigger", { 
	filter => {value => 2},
}));

