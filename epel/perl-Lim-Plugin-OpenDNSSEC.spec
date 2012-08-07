Name:           perl-Lim-Plugin-OpenDNSSEC
Version:        0.12
Release:        1%{?dist}
Summary:        Lim - Framework for RESTful JSON/XML, JSON-RPC, XML-RPC and SOAP

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim-plugin-opendnssec/
Source0:        lim-plugin-opendnssec-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
# Needed for test
BuildRequires:  perl(Test::Simple)

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Lim provides a framework for calling plugins over multiple protocols.
It uses AnyEvent for async operations and SOAP::Lite, XMLRPC::Lite and JSON::XS
for processing protocol messages.

%package -n perl-Lim-Plugin-OpenDNSSEC-Common
Summary: Common perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-OpenDNSSEC-Common
Common perl libraries for OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-Server
Summary: Server perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-OpenDNSSEC-Server
Server perl libraries for OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-Client
Summary: Client perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-OpenDNSSEC-Client
Client perl libraries for communicating with the OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-CLI
Summary: CLI perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Plugin-OpenDNSSEC-CLI
CLI perl libraries for controlling a local or remote OpenDNSSEC installation
via OpenDNSSEC Lim plugin.


%prep
%setup -q -n lim-plugin-opendnssec


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files -n perl-Lim-Plugin-OpenDNSSEC-Common
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::OpenDNSSEC.3*
%{perl_vendorlib}/Lim/Plugin/OpenDNSSEC.pm

%files -n perl-Lim-Plugin-OpenDNSSEC-Server
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::OpenDNSSEC::Server.3*
%{perl_vendorlib}/Lim/Plugin/OpenDNSSEC/Server.pm

%files -n perl-Lim-Plugin-OpenDNSSEC-Client
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::OpenDNSSEC::Client.3*
%{perl_vendorlib}/Lim/Plugin/OpenDNSSEC/Client.pm

%files -n perl-Lim-Plugin-OpenDNSSEC-CLI
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Plugin::OpenDNSSEC::CLI.3*
%{perl_vendorlib}/Lim/Plugin/OpenDNSSEC/CLI.pm


%changelog
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora

