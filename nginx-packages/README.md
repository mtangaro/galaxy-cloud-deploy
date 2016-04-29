# NGINX RPM Build directory

Modifications to the upstream  nginx package to add the upload (and possibly other) module(s).

The package is built for CentOS7.

INSTALL:
========

Clone rpmbuild directory and

rpmbuild -ba ~/rpmbuild/SPECS/nginx.spec

FROM NGINX SRC:
==============

sudo su -

rpm -Uvh http://nginx.org/packages/centos/7/SRPMS/nginx-1.8.1-1.el7.ngx.src.rpm

mv /root/rpmbuild/ /home/galaxy/ && chown -R galaxy. /home/galaxy/rpmbuild

edit spec file.

rpmbuild -ba ~/rpmbuild/SPECS/nginx.spec

credit to:
https://www.tekovic.com/adding-custom-modules-to-nginx-rpm - adapted for CentOS7
