#!/usr/bin/perl
# this script will update interface names from DNS PTR lookups

use strict;
use warnings;

use Data::Dumper;
use Socket;
use Net::DNS;
use Net::IP;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Net::Zabbix;

sub resolve_ptr;

my $z = Net::Zabbix->new(
	url =>"https://noc.ninja/zabbix/", 
	username => 'APIUser', 
	password => 'calvin',
	verify_ssl => 0,
	debug => 1,
	trace => 0,
);
$z->output(Net::Zabbix::OUTPUT_REFER);
my $resolver = Net::DNS::Resolver->new(nameservers => [ '10.11.12.13' ]);

my $hosts = $z->get("host", { 
	output => Net::Zabbix::OUTPUT_EXTEND,
	# selectItems => Net::Zabbix::OUTPUT_REFER,
	selectInterfaces => Net::Zabbix::OUTPUT_EXTEND,
	# filter => { status => 0 },
	# limit => 100,
});

my @interface_updates = ();
my @host_updates = ();

for my $h (@{$hosts->{result}}) {
	if ($h->{host} =~ /^\d+\.\d+\.\d+\.\d+$/) {
		printf("FOUND_HOST(%s)\n", $h->{host});
		my $hostname = resolve_ptr($h->{name});
		if ($hostname && $hostname ne '') {
			printf("HOST(%s,* %s)\n", $h->{hostid}, $hostname);
			push @host_updates, { hostid => $h->{hostid}, host => $hostname, name => ''};
		}
		else {
			printf("HOST(%s,N/A)\n", $h->{hostid});
		}
	}
	else {
		printf("HOST(%s,%s)\n", $h->{hostid}, $h->{name});
	}

	for my $i (@{$h->{interfaces}}) {
		printf("FOUND_INTERFACE(%s)\n", $i->{ip});
		if ($i->{dns}) {
			printf("INTERFACE(%s,%s,%s)\n", $i->{interfaceid}, $i->{ip}, $i->{dns});
		}
		else {
			my $name = resolve_ptr($i->{ip});
			if ($name && $name ne '') {
				printf("INTERFACE(%s,%s,%s)\n", $i->{interfaceid}, $i->{ip}, $name);
				push @interface_updates, { interfaceid => $i->{interfaceid}, dns => $name };
			}
			else {
				printf("INTERFACE(%s,%s,N/A)\n", $i->{interfaceid}, $i->{ip});
			}
		}

	}
}

for my $i (@interface_updates) {
	$z->update('hostinterface', $i);
}

sub resolve_ptr {
	my $address = shift;
	my $ipaddr = Net::IP->new($address);
	my $reply = $resolver->query($ipaddr->reverse_ip, 'PTR');

	return ''
		unless $reply;

	my @a = $reply->answer;
	return $a[0]->ptrdname if @a;
	return '';
};

1;
