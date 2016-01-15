#!/bin/bash -x
VERSION=$(perl -Ilib -MNet::Zabbix -e '$Net::Zabbix::VERSION =~ /^v(.*)/; print "$1\n";')
sed -e "s/^Version:(\s\s*).*/Version:\1$VERSION/g" -i contrib/perl-Net-Zabbix.spec
cp contrib/perl-Net-Zabbix.spec ~/rpmbuild/SPECS/perl-Net-Zabbix.spec
pushd ..
rm -rf Net-Zabbix-2
git clone file://$PWD/Net-Zabbix Net-Zabbix-2
rm -rf ~/rpmbuild/SOURCES/v2.tar.gz
tar cvfz ~/rpmbuild/SOURCES/v2.tar.gz Net-Zabbix-2
rpmbuild -ba ~/rpmbuild/SPECS/perl-Net-Zabbix.spec 
popd
