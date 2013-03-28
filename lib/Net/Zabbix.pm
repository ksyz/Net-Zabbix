package Net::Zabbix;

use strict;
use warnings;
use JSON::PP;
use LWP::UserAgent;
use Scalar::Util qw(reftype);
use Carp;
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(strftime);

# useful defaults
use constant {
	Z_AGENT_PORT => 10050,
	Z_SERVER_PORT => 10051,
	Z_SNMP_PORT => 161,
};

# zabbix api constants definitions
use constant {
	OUTPUT_EXTEND	=> 'extend',
	OUTPUT_REFER	=> 'refer',
	OUTPUT_SHORTEN	=> 'shorten',
};

use constant {
	HOST_INTERFACE_SECONDARY => 0,
	HOST_INTERFACE_PRIMARY => 1,

	HOST_INTERFACE_TYPE_UNKNOWN => 0,
	HOST_INTERFACE_TYPE_AGENT => 1,
	HOST_INTERFACE_TYPE_SNMP => 2,
	HOST_INTERFACE_TYPE_IPMI => 3,
	HOST_INTERFACE_TYPE_JMX => 4,

	HOST_USE_DNS => 0,
	HOST_USE_IP => 1,

	HOST_STATUS_ON => 0,
	HOST_STATUS_OFF => 1,
};

use constant {
	ITEM_TYPE_AGENT => 0,
	ITEM_TYPE_SNMP1 => 1,
	ITEM_TYPE_TRAPPER => 2,
	ITEM_TYPE_SIMPLE => 3,
	ITEM_TYPE_SNMP2 => 4,
	ITEM_TYPE_INTERN => 5,
	ITEM_TYPE_SNMP3 => 6,
	ITEM_TYPE_AAGENT => 7, # zabbix agent (active)
	ITEM_TYPE_AGGR => 8,
	ITEM_TYPE_HTTP => 9,
	ITEM_TYPE_EXTERN => 10,
	ITEM_TYPE_DBMON => 11,
	ITEM_TYPE_IPMI => 12,
	ITEM_TYPE_SSH => 13,
	ITEM_TYPE_TELNET => 14,
	ITEM_TYPE_CALC => 15,
	ITEM_TYPE_JMX => 16,
	ITEM_TYPE_SNMPT => 17,

	ITEM_STATUS_ACTIVE => 0,
	ITEM_STATUS_DISABLED => 1,
	ITEM_STATUS_NOT_SUP => 3,

	ITEM_VALUE_FLOAT => 0,
	ITEM_VALUE_CHAR => 1,
	ITEM_VALUE_LOG => 2,
	ITEM_VALUE_UINT => 3,
	ITEM_VALUE_TEXT => 4,

	ITEM_DATA_DEC => 0,
	ITEM_DATA_OCT => 1,
	ITEM_DATA_HEX => 2,
	ITEM_DATA_BIN => 3, # same as BOOL-ean
	ITEM_DATA_BOOL => 3,

	ITEM_DELTA_ASIS => 0,
	ITEM_DELTA_PERSEC => 1,
	ITEM_DELTA_CHANGE => 2,

	ITEM_SSH_AUTH_PASSWORD => 0,
	ITEM_SSH_AUTH_PUBKEY => 1,

	ITEM_FLAG_PLAIN => 0,
	ITEM_FLAG_DISCOVERED => 4,

	ITEM_SNMP_PRIV_NANP => 0,
	ITEM_SNMP_PRIV_ANP => 1,
	ITEM_SNMP_PRIV_AP => 2
};

use constant {
	TRIGGER_STATUS_ACTIVE => 0,
	TRIGGER_STATUS_DISABLED => 1,
	TRIGGER_VALUE_OK => 2,
	TRIGGER_VALUE_PROBLEM => 3,
	TRIGGER_VALUE_ON => 4,

	TRIGGER_SEVERITY_UNKN => 0,
	TRIGGER_SEVERITY_INFO => 1,
	TRIGGER_SEVERITY_WARN => 2,
	TRIGGER_SEVERITY_AVRG => 3,
	TRIGGER_SEVERITY_HIGH => 4,
	TRIGGER_SEVERITY_DISA => 5,
	
	TRIGGER_TYPE_NORMAL => 0,
	TRIGGER_TYPE_MULTI => 1,

	TRIGGER_FLAG_GOOD => 0,
	TRIGGER_FLAG_UNCERTAIN => 1,
	
	TRIGGER_STATUS_ICMPPING_FAIL => 0,
	TRIGGER_STATUS_ICMPPING_SUCCESS => 1,
};

# http://www.zabbix.com/documentation/2.0/manual/appendix/api/user/definitions
use constant {
	USER_TYPE_USER => 1,
	USER_TYPE_ADMIN => 2,
	USER_TYPE_SUPERADMIN => 3,
	USER_TYPE_ROOT => 3, # same as Super Admin

	# default supported theme names
	USER_THEME_1 => 'originalblue', 
	USER_THEME_2 => 'darkblue',
	USER_THEME_3 => 'darkorange',

	# 0 seconds means disabled
	USER_AUTOLOGIN_DISABLE => 0,
};

# http://www.zabbix.com/documentation/2.0/manual/appendix/api/usergroup/definitions
use constant {
	GROUP_ACCESS_DEFAULT => 0,
	GROUP_ACCESS_INTERNAL => 1,
	GROUP_ACCESS_DISABLED => 2,
	
	GROUP_STATUS_ENABLED => 0,
	GROUP_STATUS_DISABLED => 1,

	GROUP_DEBUG_ENABLED => 1,
	GROUP_DEBUG_DISABLED => 0,
};

sub new {
	my ($class, $url, $user, $password, $debug, $trace, $config_file) = @_;

	my $self = bless {
		UserAgent => undef,
		Request   => undef,
		Count     => 1,
		Auth      => undef,
		API_URL   => $url,
		Output    => OUTPUT_EXTEND,
		Debug     => $debug ? 1 : 0,
		Trace     => $trace ? 1 : 0,
		User      => $user,
		Password  => $password,
		_call_start => 0,
	}, $class;
	
	# init json object
	$self->_json;
	# init useragent
	$self->ua;
	# authenticate
	$self->auth;

	return $self;
}

sub output {
	my $self = shift;
	
	$self->{Output} = $_[0]
		if (@_);
	
	return $self->{Output};
}

sub ua {
	my $self = shift;

	unless ($self->{UserAgent}) {
		$self->{UserAgent} = LWP::UserAgent->new;
		$self->{UserAgent}->agent("Net::Zabbix");
		$self->{UserAgent}->timeout(3600);
	}
	
	return $self->{UserAgent};
}

sub _json {
	my $self = shift;

	unless (defined $self->{JSON}) {
		$self->{JSON} = JSON::PP->new;
		$self->{JSON}
			->ascii
			->pretty
			->allow_nonref
			->allow_blessed
			->allow_bignum; # we use PP because of bignum
	}
	return $self->{JSON};
}

sub trace {
	my $self = shift;
	
	$self->{Trace} = $_[0]
		if (@_);
	
	return $self->{Trace};
}


sub debug {	
	my $self = shift;
	
	$self->{Debug} = $_[0]
		if (@_);
	
	return $self->{Debug};
}

sub req {
	my $self = shift;
	
	unless ($self->{Request}) {
		$self->{Request} = HTTP::Request->new(POST => "$self->{API_URL}/api_jsonrpc.php");
		$self->{Request}->content_type('application/json-rpc');
	}

	return $self->{Request};
}

sub auth {
	my $self = shift;

	if (not defined $self->{Auth}) {
		$self->{Auth} = ''; # avoiding recursion
		my $res = $self->raw_request('user', 'authenticate', {
			user => $self->{User},
			password => $self->{Password},
		});

		confess $res->{error}{data}
			if defined $res->{error};
		delete $self->{Password};
		$self->{Auth} = $res->{result};
	}
	elsif ($self->{Auth} eq '') {
		return (); # empty for first auth call
	}
	
	return $self->{Auth} unless defined wantarray;
	return (auth => $self->{Auth});
}

sub next_id {
	return ++shift->{'Count'};
}

sub data_enc {
	my ($self, $data) = @_;
	my $json = $self->{JSON}->encode($data);
	
	$self->_dbgmsg("TX: ".$json) 
		if $self->{Debug};
	
	return $json;
}

sub data_dec {
	my ($self, $json) = @_;
	
	$self->_dbgmsg("RX: ".$json) 
		if $self->{Debug};

	return $self->{JSON}->decode($json);
}

sub get {
	my ($self, $object, $params) = @_;
	return $self->raw_request($object, "get", $params);
}

sub update {
	my ($self, $object, $params) = @_;
	return $self->raw_request($object, "update", $params);
}

sub delete {
	my ($self, $object, $params) = @_;
	return $self->raw_request($object, "delete", $params);
}

sub create {
	my ($self, $object, $params) = @_;
	return $self->raw_request($object, "create", $params);
}

sub exists {
	my ($self, $object, $params) = @_;
	return $self->raw_request($object, "exists", $params);
}

sub raw_request {
	my ($self, $object, $op, $params) = @_;

	if ($self->{Trace}) {
		$self->{_call_start} = [gettimeofday];
		$self->_dbgmsg("Starting method $object.$op");
	}
	
	if ($params) {
		$params->{output} = $self->{Output}
			if (reftype($params) eq 'HASH' and not defined $params->{output});
	}
	else {
		$params = [];
	}

	my $req = $self->req;
	$req->content($self->data_enc( {
		jsonrpc => "2.0",
		method => "$object.$op",
		params => $params,
		id => $self->next_id,
		($self->auth),
	}));

	my $res = $self->ua->request($req);

	unless ($res->is_success) {
		die "Can't connect to Zabbix" . $res->status_line;
	}

	if ($self->{Trace}) {
		$self->_dbgmsg("Finished method $object.$op");
		$self->_dbgmsg("Spent ".tv_interval ($self->{_call_start})."s on $object.$op");
	}

	return $self->data_dec($res->content);
}

sub _dbgmsg {
	my $self = shift;
	warn strftime('[%F %T]', localtime).' '.__PACKAGE__.' @ #'.$self->{Count}.' '.join(', ', @_)."\n";
}

1;
