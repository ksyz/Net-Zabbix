#!/usr/bin/perl
# this script will update hostnames from SNMP sysName request

use strict;
use warnings;

use Data::Dumper;
use Socket;
use Net::DNS;
use Net::IP;
use Net::SNMP;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Net::Zabbix;

my $HOST_OID = '1.3.6.1.2.1.1.5.0';

sub resolve_snmp;

my $z = Net::Zabbix->new(
	url =>"https://noc.ninja/zabbix/", 
	username => 'APIUser', 
	password => 'calvin',
	verify_ssl => 0,
	debug => 1,
	trace => 0,
);
$z->output(Net::Zabbix::OUTPUT_REFER);

my $hosts = $z->get("host", { 
	output => Net::Zabbix::OUTPUT_EXTEND,
	selectInterfaces => Net::Zabbix::OUTPUT_EXTEND,
	# filter => { status => 0 },
	limit => 2,
});

my @interface_updates = ();
my @host_updates = ();
my @snmp_interfaces = ();

for my $h (@{$hosts}) {
	my $primary;
	my $entry = { host => $h->{host}, name => $h->{name}, hostid => $h->{hostid}}; 
	for my $i (@{$h->{interfaces}}) {
		if ($i->{main} eq '1' && $i->{type} eq Net::Zabbix::HOST_INTERFACE_TYPE_SNMP) {
			$entry->{snmp} = $i->{ip};
		}
		elsif ($i->{main} eq '1' && $i->{type} eq Net::Zabbix::HOST_INTERFACE_TYPE_AGENT) {
			$entry->{icmp} = $i->{ip};
		}
	}
	push @snmp_interfaces, $entry;
}

for my $s (@snmp_interfaces) {
	next unless $s->{snmp};
	# print Dumper($s);
	printf("%s:%s\n", $s->{host}, $s->{name});
	my $hostname = resolve_snmp($s->{snmp});
	printf("\t%s -> SNMP:%s\n", $s->{snmp}, $hostname);
	next unless $hostname;
	$z->update('host', { hostid => $s->{hostid}, name => $hostname, host => $hostname});
}

sub resolve_snmp {
	my $address = shift;
	return '' unless $address;
	my $com = $address =~ /^172\.17\./ ? 'com2' : 'com1';
	my ($session, $error) = Net::SNMP->session(
		hostname => $address, 
		community => $com, 
		version => 'snmpv2c', 
		timeout => 1, 
		retries => 1);
	my $result = $session->get_request( -varbindlist => [ $HOST_OID ] );
	return $result->{$HOST_OID}
		if defined $result->{$HOST_OID};
	return '';
};

1;
