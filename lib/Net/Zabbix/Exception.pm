package Net::Zabbix::Exception;
use strict;
use warnings;
use Data::Dumper;
use base qw(Error);
use overload ('""' => 'stringify');

sub new {
	my $self = shift;
	my $text = "" . shift;
	my @args = @_;

	local $Error::Depth = $Error::Depth + 1;
	local $Error::Debug = 1;  # Enables storing of stacktrace

	return $self->SUPER::new(-text => $text, @args);
};

1;
