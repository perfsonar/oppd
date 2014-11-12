%define install_base /opt/perfsonar_ps/oppd_mp

%define relnum 2 
%define disttag pSPS
%define oppdlogdir /var/log/perfsonar/
%define oppdlogfile oppd.log

Name:			perl-perfSONAR-OPPD-MP
Version:		3.4
Release:		%{relnum}.%{disttag}
Summary:		perfSONAR OPPD Measurement Point
License:		Distributable, see LICENSE
Group:			Development/Libraries
URL:			http://www.perfsonar.net/
Source0:		perfSONAR-OPPD-MP-%{version}.%{relnum}.tar.gz
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:		noarch
Requires:		perl

%description
Executes on-demand measurements through a web interface

%package Shared
Summary:		MP Shared libs
Group:			Development/Tools

%description Shared
Shared libraries used by the on-demand MP

%package server
Summary:		MP perfSONAR daemon
Group:			Development/Tools
Requires:       perl-perfSONAR-OPPD-MP-Shared
Requires:	    ntp
Requires:       perl(HTTP::Daemon::SSL)
Requires:       perl(Config::General)
Requires:	perl(Net::DNS)
Obsoletes:      oppd
Obsoletes:      perfsonar-oppd < 0.53

%description server
Daemon that runs MP

%package BWCTL
Summary:		BWCTL MP
Group:			Development/Tools
Requires:       perl-perfSONAR-OPPD-MP-Shared
Requires:       perl-perfSONAR-OPPD-MP-server
Requires:	    bwctl >= 1.5

%description BWCTL
Provides on-demand BWCTL measurements through a web interface

%package OWAMP
Summary:		OWAMP MP
Group:			Development/Tools
Requires:       perl-perfSONAR-OPPD-MP-Shared
Requires:       perl-perfSONAR-OPPD-MP-server
Requires:       perl(IO::Tty) >= 1.02
Requires:       perl(IPC::Run)
Requires:	    owamp

%description OWAMP
Provides on-demand OWAMP measurements through a web interface

%pre server
/usr/sbin/groupadd perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :
if [ ! -d "%{oppdlogdir}" ]; then
    mkdir -p %{oppdlogdir}
fi
if [ ! -f "%{oppdlogdir}%{oppdlogfile}" ]; then
    touch %{oppdlogdir}%{oppdlogfile}
    chown perfsonar:perfsonar %{oppdlogdir}%{oppdlogfile}
fi
exit 0

%pre BWCTL
/usr/sbin/groupadd perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :
if [ "$1" = 0 ] ; then
/sbin/service oppd stop > /dev/null 2>&1
fi
exit 0

%pre OWAMP
/usr/sbin/groupadd perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :
if [ "$1" = 0 ] ; then
/sbin/service oppd stop > /dev/null 2>&1
fi
exit 0

%prep
%setup -q -n perfSONAR-OPPD-MP-%{version}.%{relnum}

%build

%install
rm -rf %{buildroot}
make ROOTPATH=%{buildroot}/%{install_base} rpminstall
mkdir -p %{buildroot}/etc/init.d
install -m 0755 scripts/oppd %{buildroot}/etc/init.d/oppd
mkdir -p %{buildroot}/etc/sysconfig
install -m 0644 etc/oppd.sysconfig %{buildroot}/etc/sysconfig/oppd
mkdir -p %{buildroot}/etc/httpd/conf.d

%clean
rm -rf %{buildroot}

%post server
/sbin/chkconfig --add oppd

%post BWCTL
/sbin/service oppd start > /dev/null 2>&1

%post OWAMP
/sbin/service oppd start > /dev/null 2>&1

%preun server
if [ "$1" = 0 ] ; then
/sbin/service oppd stop
/sbin/chkconfig --del oppd
fi
if [ -f "%{oppdlogdir}%{oppdlogfile}" ]; then
    rm -rf %{oppdlogdir}%{oppdlogfile}
fi
exit 0

%preun BWCTL
if [ "$1" = 0 ] ; then
/sbin/service oppd stop > /dev/null 2>&1
fi
exit 0

%preun OWAMP
if [ "$1" = 0 ] ; then
/sbin/service oppd stop > /dev/null 2>&1
fi
exit 0

%postun BWCTL
if [ "$1" -ge 1 ]; then
/sbin/service oppd condrestart > /dev/null 2>&1
fi
exit 0

%postun OWAMP
if [ "$1" -ge 1 ]; then
/sbin/service oppd condrestart > /dev/null 2>&1
fi
exit 0

%files Shared
%defattr(-,perfsonar,perfsonar,-)
%{install_base}/lib/NMWG/*
%{install_base}/lib/NMWG.pm
%{install_base}/lib/perfSONAR.pm
%{install_base}/lib/perfSONAR/Client/*
%{install_base}/lib/perfSONAR/DataStruct/*
%{install_base}/lib/perfSONAR/SOAP/*
%{install_base}/lib/perfSONAR/AS.pm
%{install_base}/lib/perfSONAR/Auth.pm
%{install_base}/lib/perfSONAR/DataStruct.pm
%{install_base}/lib/perfSONAR/Echo.pm
%{install_base}/lib/perfSONAR/LS.pm
%{install_base}/lib/perfSONAR/MA.pm
%{install_base}/lib/perfSONAR/MP.pm
%{install_base}/lib/perfSONAR/Request.pm
%{install_base}/lib/perfSONAR/SOAP.pm
%{install_base}/lib/perfSONAR/Selftest.pm
%{install_base}/lib/perfSONAR/Tools.pm

%files server
%defattr(-,perfsonar,perfsonar,-)
%doc %{install_base}/doc/*
%attr(755, perfsonar, perfsonar) %{install_base}/bin/oppd.pl
%{install_base}/scripts/oppd
%config /etc/init.d/oppd
%config %{install_base}/etc/oppd.conf
%config %{install_base}/etc/oppd.sysconfig
%config %{install_base}/etc/oppd.d/*.xml
%config /etc/sysconfig/oppd

%files BWCTL
%defattr(-,perfsonar,perfsonar,-)
%config %{install_base}/etc/oppd.d/bwctl.conf
%{install_base}/lib/perfSONAR/MP/BWCTL.pm

%files OWAMP
%defattr(-,perfsonar,perfsonar,-)
%config %{install_base}/etc/oppd.d/owamp.conf
%{install_base}/lib/perfSONAR/MP/OWAMP.pm

%changelog
*  Fri Sep 26 2014 hakan.calim@fau.de
- Added creation of log file in /var/log/perfsonar/oppd.log.
- Fix bug in preun of server.
*  Wed May 21 2014 andy@es.net 
- Combined packages into single spec file
