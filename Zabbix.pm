# $Id: Zabbix.pm 16176 2010-02-26 21:08:19Z stjohnston $
# $URL: https://svn.gmp.ntta.com/gmp/branches/NTTC-gmp/lib/perl/GMP/WebServices/Zabbix.pm $

package GMP::WebServices::Zabbix;

use strict;
use JSON::XS;
use LWP::UserAgent;

use GMP::Error qw(error);

my $Argparser = GMP::Util::ArgParser->objnew('GMP::WebServices::Zabbix', {
    url         => 'STR',
    user        => 'STR',
    password    => 'STR',
    api_link    => 'STR',
});

sub new {
    my ($class, $url, $user, $password, $api_link) =
        $Argparser->parse('class ; url user password api_link', \@_);

    if ($api_link) {
        ($url, $user, $password) = split(/\|/, readlink($api_link));
    }

    my $ua = LWP::UserAgent->new;
    $ua->agent("GMP::WebServices::Zabbix");

    my $req = HTTP::Request->new(POST => "$url/api_jsonrpc.php");
    $req->content_type('application/json-rpc');

    $req->content(encode_json( {
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
      error("Can't connect to Zabbix", $res->status_line);
    }

    my $auth = decode_json($res->content)->{'result'};

    return bless {
        UserAgent => $ua,
        Request   => $req,
        Count     => 1,
        Auth      => $auth,
    }, $class;
}

sub ua {
    return shift->{'UserAgent'};
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

sub get {
    my ($self, $object, $params) = @_;

    my $req = $self->req;
    $req->content(encode_json( {
        jsonrpc => "2.0",
        method => "$object.get",
        params => $params,
        auth => $self->auth,
        id => $self->next_id,
    }));

    my $res = $self->ua->request($req);

    unless ($res->is_success) {
      error("Can't connect to Zabbix", $res->status_line);
    }

    return decode_json($res->content);
}

1;
