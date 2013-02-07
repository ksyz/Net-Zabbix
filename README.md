Net::Zabbix is simple and thin layer between Zabbix API and your code. It
doesn't implement much, except authentication and request counting. There
are few helper methods to simplify calling methods such as
create/get/update/delete/exists. There is no checking of method parameters,
as that is work for-and already implemented on server side.

Consult Zabbix API documentation for details.

- http://www.zabbix.com/wiki/doc/api
- http://www.zabbix.com/documentation/1.8/api
- http://www.zabbix.com/documentation/2.0/manual/appendix/api/api

### Note

Module is fully compatible with Zabbix 2.0 and 1.8.

### Example

This will list hosts like '*test*', limited only by access level for API
user. So, remember to add user to appropriate groups and assign enough
permissions.

```perl
use Net::Zabbix;

my $z = Net::Zabbix->new("http://server/zabbix", "API", "calvin", 1);
my $r = $z->get("host", {
        filter => undef,
        search => {
            host => "test",
        },
    }
);

```

### License

Code diverged a lot from original branch. Consider my additions as WTF-PL.

