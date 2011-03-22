package Net::Zabbix;

use strict;
use JSON::XS;
use LWP::UserAgent;
use Data::Dumper;

sub new {
	my ($class, $url, $user, $password, $debug) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->agent("Net::Zabbix");

	my $req = HTTP::Request->new(POST => "$url/api_jsonrpc.php");
	$req->content_type('application/json-rpc');

	my $self = bless {
		UserAgent => $ua,
		Request   => $req,
		Count     => 1,
		Auth      => undef,
		Debug     => $debug ? 1 : 0,
	}, $class;

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

	unless ($res->is_success) {
		die "Can't connect to Zabbix" . $res->status_line;
	}

	my $auth = $self->data_dec($res->content)->{'result'};
	$self->{Auth} = $auth;

	return $self;
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
	my $json = encode_json($data);
	warn Dumper($json) if $self->{Debug};
	return $json;
}

sub data_dec {
	my ($self, $json) = @_;
	warn Dumper($json) if $self->{Debug};
	my $data = decode_json($json);
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
