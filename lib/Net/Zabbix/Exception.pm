package Net::Zabbix::Exception;
use strict;
use warnings;
use base qw(Error);
use overload ('""' => 'stringify');

sub new {
	my $self = shift;
	my $obj = shift;

	my $class = ref($self) || $self;

	my $text = sprintf('%s: CALL(%i), MESSAGE(%s), DATA(%s)', $class, $obj->{id}, $obj->{error}{message}, $obj->{error}{data}) ;
	my %args = (error => $obj->{error}, debug => $obj->{error}{debug}, obj => $obj);

	local $Error::Depth = $Error::Depth + 1;
	local $Error::Debug = 1;  # Enables storing of stacktrace

	return $self->SUPER::new(-text => $text, %args);
};

1;
