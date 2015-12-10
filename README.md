Net::Zabbix is simple and thin layer between Zabbix API and your code. It
doesn't implement much, except authentication and request counting. There
are few helper methods to simplify calling methods such as
create/get/update/delete/exists. There is no checking of method parameters,
as that is work for-and already implemented on server side.

Consult Zabbix API documentation for details.

- [Zabbix API Wiki](http://www.zabbix.com/wiki/doc/api)
- [Zabbix 1.8 API](http://www.zabbix.com/documentation/1.8/api)
- [Zabbix 2.0 API](http://www.zabbix.com/documentation/2.0/manual/appendix/api/api)
- [Zabbix 2.2 API](https://www.zabbix.com/documentation/2.2/manual/api/reference)

### Note

Module is compatible and tested with Zabbix 1.8, 2.0 and 2.2. But shuld 
work with any version.

### Example

This will list hosts like '*test*', limited only by access level for API
user. So, remember to add user to appropriate groups and assign enough
permissions.

```perl
use Net::Zabbix;

my $z = Net::Zabbix->new(
	url => "https://server/zabbix/", 
	username => 'APIUser', 
	password => 'calvin',
	verify_ssl => 0,
	debug => 1,
	trace => 0,
);

my $r = $z->get("host", {
        filter => undef,
        search => {
            host => "test",
        },
    }
);

```
### Package

RPM package for Enterprise Linux 7 (comaptible with Fedora, just force it) could be found in [COPR](https://copr.fedoraproject.org/coprs/ksyz/el7-perl) repository.

### License

Code diverged a lot from original branch. Consider my additions as WTF-PL.

