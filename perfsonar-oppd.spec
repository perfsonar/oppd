%define install_base /usr/lib/perfsonar/
%define config_base  /etc/perfsonar

# init scripts must be located in the 'scripts' directory
%define init_script_1 perfsonar-oppd-server
%define oppdlogdir /var/log/perfsonar/
%define oppdlogfile oppd-server.log

%define relnum 0.0.a1

Name:			perfsonar-oppd
Version:		3.5.1
Release:		%{relnum}
Summary:		perfSONAR OPPD Measurement Point
License:		Distributable, see LICENSE
Group:			Development/Libraries
URL:			http://www.perfsonar.net/
Source0:		perfsonar-oppd-%{version}.%{relnum}.tar.gz
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:		noarch
Requires:		perl

%description
Executes on-demand measurements through a web interface

%package shared
Summary:        MP Shared libs
Group:          Development/Tools
Obsoletes:      perl-perfSONAR-OPPD-MP-Shared
Provides:       perl-perfSONAR-OPPD-MP-Shared

%description shared
Shared libraries used by the on-demand MP

%package server
Summary:		MP perfSONAR daemon
Group:			Development/Tools
Requires:       perfsonar-oppd-shared
Requires:	    ntp
Requires:       perl(HTTP::Daemon::SSL)
Requires:       perl(Config::General)
Requires:	perl(Net::DNS)
Requires:	perl(Net::INET6Glue)
Requires:       libperfsonar-esmond-perl 
Obsoletes:      oppd
Obsoletes:      perfsonar-oppd < 0.53
Obsoletes:      perl-perfSONAR-OPPD-MP-server
Provides:       perl-perfSONAR-OPPD-MP-server

%description server
Daemon that runs MP

%package bwctl
Summary:		BWCTL MP
Group:			Development/Tools
Requires:       perfsonar-oppd-shared
Requires:       perfsonar-oppd-server
Requires:	    bwctl >= 1.5
Obsoletes:      perl-perfSONAR-OPPD-MP-BWCTL
Provides:       perl-perfSONAR-OPPD-MP-BWCTL

%description bwctl
Provides on-demand BWCTL measurements through a web interface

%package owamp
Summary:		OWAMP MP
Group:			Development/Tools
Requires:       perfsonar-oppd-shared
Requires:       perfsonar-oppd-server
Requires:       perl(IO::Tty) >= 1.02
Requires:       perl(IPC::Run)
Requires:	    owamp
Obsoletes:      perl-perfSONAR-OPPD-MP-OWAMP
Provides:       perl-perfSONAR-OPPD-MP-OWAMP

%description owamp
Provides on-demand OWAMP measurements through a web interface

%pre shared
if rpm -q --quiet perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "It seems you previously had the perl-perfSONAR-OPPD-MP-server-3.4-1 package installed which contains a small packaging problem."
    echo " To avoid any  unnecessary warnings in the future, you need to remove this package manually with the command: "
    echo "rpm -e --nodeps --nopreun perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch"
    echo "After manual remove of the package start installation or upgrade again."
    exit 1
fi
exit 0

%pre server
if rpm -q --quiet perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "It seems you previously had the perl-perfSONAR-OPPD-MP-server-3.4-1 package installed which contains a small packaging problem."
    echo " To avoid any  unnecessary warnings in the future, you need to remove this package manually with the command: "
    echo "rpm -e --nodeps --nopreun perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch"
    echo "After manual remove of the package start installation or upgrade again."
    exit 1
fi
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

%pre bwctl
if rpm -q --quiet perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "It seems you previously had the perl-perfSONAR-OPPD-MP-server-3.4-1 package installed which contains a small packaging problem."
    echo " To avoid any  unnecessary warnings in the future, you need to remove this package manually with the command: "
    echo "rpm -e --nodeps --nopreun perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch"
    echo "After manual remove of the package start installation or upgrade again."
    exit 1
fi

/usr/sbin/groupadd perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :
if [ "$1" = 0 ] ; then
    /sbin/service perfsonar-oppd-server stop > /dev/null 2>&1
fi
exit 0

%pre owamp
if rpm -q --quiet perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "It seems you previously had the perl-perfSONAR-OPPD-MP-server-3.4-1 package installed which contains a small packaging problem."
    echo " To avoid any  unnecessary warnings in the future, you need to remove this package manually with the command: "
    echo "rpm -e --nodeps --nopreun perl-perfSONAR-OPPD-MP-server-3.4-1.pSPS.noarch"
    echo "After manual remove of the package start installation or upgrade again."
    exit 1
fi

/usr/sbin/groupadd perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :
if [ "$1" = 0 ] ; then
/sbin/service perfsonar-oppd-server stop > /dev/null 2>&1
fi
exit 0

%prep
%setup -q -n perfsonar-oppd-%{version}.%{relnum}

%build

%install
rm -rf %{buildroot}

make ROOTPATH=%{buildroot}/%{install_base} CONFIGPATH=%{buildroot}/%{config_base} install

mkdir -p %{buildroot}/etc/init.d

install -D -m 0755 scripts/%{init_script_1} %{buildroot}/etc/init.d/%{init_script_1}
rm -rf %{buildroot}/%{install_base}/scripts/

mkdir -p %{buildroot}/etc/sysconfig
install -m 0644 etc/oppd-server.sysconfig %{buildroot}/etc/sysconfig/oppd-server
rm -f %{buildroot}/%{config_base}/oppd-server.sysconfig

mkdir -p %{buildroot}/etc/httpd/conf.d

%clean
rm -rf %{buildroot}

%post server
/sbin/chkconfig --add perfsonar-oppd-server
if [ "$1" = "1" ]; then
     # clean install, check for pre 3.5.1 files
    if [ -e "/opt/perfsonar_ps/oppd_mp/etc/oppd.conf" ]; then
        mv %{config_base}/oppd-server.conf %{config_base}/oppd-server.conf.default
        mv /opt/perfsonar_ps/oppd_mp/etc/oppd.conf %{config_base}/oppd-server.conf
        sed -i "s:oppd\.d:oppd-server.d:g" %{config_base}/oppd-server.conf
    fi
    if [ -e "/etc/sysconfig/oppd" ]; then
        mv -f /etc/sysconfig/oppd /etc/sysconfig/oppd-server
        sed -i "s:/opt/perfsonar_ps/oppd_mp/bin/oppd.pl:/usr/lib/perfsonar/bin/oppd-server.pl:g" /etc/sysconfig/oppd-server
        sed -i "s:/opt/perfsonar_ps/oppd_mp/etc/oppd.conf:/etc/perfsonar/oppd-server.conf:g" /etc/sysconfig/oppd-server
    fi
fi

%post bwctl
/sbin/service perfsonar-oppd-server start > /dev/null 2>&1
if [ "$1" = "1" ]; then
     # clean install, check for pre 3.5.1 files
    if [ -e "/opt/perfsonar_ps/oppd_mp/etc/oppd.d/bwctl.conf" ]; then
        mv %{config_base}/oppd-server.d/bwctl.conf %{config_base}/oppd-server.d/bwctl.conf.default
        mv /opt/perfsonar_ps/oppd_mp/etc/oppd.d/bwctl.conf %{config_base}/oppd-server.d/bwctl.conf
    fi
fi

%post owamp
/sbin/service perfsonar-oppd-server start > /dev/null 2>&1
if [ "$1" = "1" ]; then
     # clean install, check for pre 3.5.1 files
    if [ -e "/opt/perfsonar_ps/oppd_mp/etc/oppd.d/owamp.conf" ]; then
        mv %{config_base}/oppd-server.d/owamp.conf %{config_base}/oppd-server.d/owamp.conf.default
        mv /opt/perfsonar_ps/oppd_mp/etc/oppd.d/owamp.conf %{config_base}/oppd-server.d/owamp.conf
    fi
fi

%preun server
if [ "$1" = 0 ] ; then
    /sbin/service perfsonar-oppd-server stop
    /sbin/chkconfig --del perfsonar-oppd-server
fi
if [ -f "%{oppdlogdir}%{oppdlogfile}" ]; then
    rm -rf %{oppdlogdir}%{oppdlogfile}
fi
exit 0

%preun bwctl
if [ "$1" = 0 ] ; then
    /sbin/service perfsonar-oppd-server stop > /dev/null 2>&1
fi
exit 0

%preun owamp
if [ "$1" = 0 ] ; then
    /sbin/service perfsonar-oppd-server stop > /dev/null 2>&1
fi
exit 0

%postun bwctl
if [ "$1" -ge 1 ]; then
    /sbin/service perfsonar-oppd-server condrestart > /dev/null 2>&1
fi
exit 0

%postun owamp
if [ "$1" -ge 1 ]; then
    /sbin/service perfsonar-oppd-server condrestart > /dev/null 2>&1
fi
exit 0

%files shared
%defattr(-,perfsonar,perfsonar,-)
%{install_base}/lib/NMWG/*
%{install_base}/lib/NMWG.pm
%{install_base}/lib/perfSONAR.pm
%{install_base}/lib/perfSONAR/Client/*
%{install_base}/lib/perfSONAR/DataStruct/*
%{install_base}/lib/perfSONAR/Esmond/*
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
%attr(755, perfsonar, perfsonar) %{install_base}/bin/oppd-server.pl
%config /etc/init.d/perfsonar-oppd-server
%config %{config_base}/oppd-server.conf
%config %{config_base}/oppd-server.d/*.xml
%config /etc/sysconfig/oppd-server

%files bwctl
%defattr(-,perfsonar,perfsonar,-)
%config %{config_base}/oppd-server.d/bwctl.conf
%{install_base}/lib/perfSONAR/MP/BWCTL.pm

%files owamp
%defattr(-,perfsonar,perfsonar,-)
%config %{config_base}/oppd-server.d/owamp.conf
%{install_base}/lib/perfSONAR/MP/OWAMP.pm

%changelog
*  Fri Sep 26 2014 hakan.calim@fau.de
- Added creation of log file in /var/log/perfsonar/oppd.log.
- Fix bug in preun of server.
*  Wed May 21 2014 andy@es.net 
- Combined packages into single spec file
