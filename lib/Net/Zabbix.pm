package Net::Zabbix;

use strict;
use JSON::PP;
use LWP::UserAgent;
use Scalar::Util qw(reftype);
# useful defaults
use constant {
	Z_AGENT_PORT => 10050,
	Z_SERVER_PORT => 10051,
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
	ITEM_TYPE_AAGENT => 7,
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
	ITEM_STATUS_NOT_SUP => 2,

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
};

sub new {
	my ($class, $url, $user, $password, $debug) = @_;

	my $json = JSON::PP->new;
	$json
		->ascii
		->pretty
		->allow_nonref
		->allow_blessed
		->allow_bignum;

	my $ua = LWP::UserAgent->new;
	$ua->agent("Net::Zabbix");

	my $req = HTTP::Request->new(POST => "$url/api_jsonrpc.php");
	$req->content_type('application/json-rpc');

	my $self = bless {
		UserAgent => $ua,
		Request   => $req,
		Count     => 1,
		Auth      => undef,
		Output		=> OUTPUT_EXTEND,
		Debug     => $debug ? 1 : 0,
	}, $class;
	
	$self->{JSON} = $json;

	$req->content($self->data_enc({
		jsonrpc => "2.0",
		method => "user.authenticate",
		params => {
			user => $user,
			password => $password,
		},
		id => 1,
	}));

	my $res = $ua->request($req);

	die "Can't connect to Zabbix: " . $res->status_line 
		unless ($res->is_success);

	my $auth = $self->data_dec($res->content)->{'result'};
	$self->{Auth} = $auth;

	$JSON::Pretty = 1
		if $self->{Debug};

	return $self;
}

sub output {
	return shift->{'Output'};
}

sub ua {
	return shift->{'UserAgent'};
}

sub debug {
	return shift->{'Debug'};
}

sub req {
	return shift->{'Request'};
}

sub auth {
	return shift->{'Auth'};
}

sub next_id {
	return ++shift->{'Count'};
}

sub data_enc {
	my ($self, $data) = @_;
	
	my $json = $self->{JSON}->encode($data);
	
	warn "TX: ".$json 
		if $self->{Debug};
	
	return $json;
}

sub data_dec {
	my ($self, $json) = @_;
	
	warn "RX: ".$json 
		if $self->{Debug};
	
	my $data = $self->{JSON}->decode($json);
	
	return $data;
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
		auth => $self->auth,
		id => $self->next_id,
	}));

	my $res = $self->ua->request($req);

	unless ($res->is_success) {
		die "Can't connect to Zabbix" . $res->status_line;
	}

	return $self->data_dec($res->content);
}

1;
