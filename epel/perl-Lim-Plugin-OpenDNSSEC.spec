Name:           perl-Lim-Plugin-OpenDNSSEC
Version:        0.13
Release:        1%{?dist}
Summary:        Lim::Plugin::OpenDNSSEC - OpenDNSSEC management plugin for Lim

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim-plugin-opendnssec/
Source0:        lim-plugin-opendnssec-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple)
BuildRequires:  perl(Lim) >= 0.16

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:  perl(Lim) >= 0.16

%description
This plugin lets you manage a OpenDNSSEC installation via Lim.

%package -n perl-Lim-Plugin-OpenDNSSEC-Common
Summary: Common perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Plugin-OpenDNSSEC-Common
Common perl libraries for OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-Server
Summary: Server perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Plugin-OpenDNSSEC-Server
Server perl libraries for OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-Client
Summary: Client perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Plugin-OpenDNSSEC-Client
Client perl libraries for communicating with the OpenDNSSEC Lim plugin.

%package -n perl-Lim-Plugin-OpenDNSSEC-CLI
Summary: CLI perl libraries for OpenDNSSEC Lim plugin
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Plugin-OpenDNSSEC-CLI
CLI perl libraries for controlling a local or remote OpenDNSSEC installation
via OpenDNSSEC Lim plugin.

%package -n lim-management-console-opendnssec
Requires: lim-management-console-common >= 0.16
Summary: OpenDNSSEC Lim plugin Management Console files
Group: Development/Libraries
Version: 0.13
%description -n lim-management-console-opendnssec
OpenDNSSEC Lim plugin Management Console files.


%prep
%setup -q -n lim-plugin-opendnssec


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
mkdir -p %{buildroot}%{_datadir}/lim/html
mkdir -p %{buildroot}%{_datadir}/lim/html/_opendnssec
mkdir -p %{buildroot}%{_datadir}/lim/html/_opendnssec/js
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/about.html %{buildroot}%{_datadir}/lim/html/_opendnssec/about.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/index.html %{buildroot}%{_datadir}/lim/html/_opendnssec/index.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/js/application.js %{buildroot}%{_datadir}/lim/html/_opendnssec/js/application.js
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/config_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/config_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/config_read.html %{buildroot}%{_datadir}/lim/html/_opendnssec/config_read.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/control_start.html %{buildroot}%{_datadir}/lim/html/_opendnssec/control_start.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/control_stop.html %{buildroot}%{_datadir}/lim/html/_opendnssec/control_stop.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_backup_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_backup_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_key_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_key_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_policy_export.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_policy_export.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_policy_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_policy_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_repository_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_repository_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_rollover_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_rollover_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_update.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_update.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/enforcer_zone_list.html %{buildroot}%{_datadir}/lim/html/_opendnssec/enforcer_zone_list.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/hsm_info.html %{buildroot}%{_datadir}/lim/html/_opendnssec/hsm_info.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_clear.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_clear.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_flush.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_flush.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_queue.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_queue.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_sign.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_sign.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_update.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_update.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/signer_zones.html %{buildroot}%{_datadir}/lim/html/_opendnssec/signer_zones.html
install -m 644 %{_builddir}/lim-plugin-opendnssec/html/_opendnssec/system_information.html %{buildroot}%{_datadir}/lim/html/_opendnssec/system_information.html


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

%files -n lim-management-console-opendnssec
%defattr(-,root,root,-)
%{_datadir}/lim/html/_opendnssec/about.html
%{_datadir}/lim/html/_opendnssec/index.html
%{_datadir}/lim/html/_opendnssec/js/application.js
%{_datadir}/lim/html/_opendnssec/config_list.html
%{_datadir}/lim/html/_opendnssec/config_read.html
%{_datadir}/lim/html/_opendnssec/control_start.html
%{_datadir}/lim/html/_opendnssec/control_stop.html
%{_datadir}/lim/html/_opendnssec/enforcer_backup_list.html
%{_datadir}/lim/html/_opendnssec/enforcer_key_list.html
%{_datadir}/lim/html/_opendnssec/enforcer_policy_export.html
%{_datadir}/lim/html/_opendnssec/enforcer_policy_list.html
%{_datadir}/lim/html/_opendnssec/enforcer_repository_list.html
%{_datadir}/lim/html/_opendnssec/enforcer_rollover_list.html
%{_datadir}/lim/html/_opendnssec/enforcer_update.html
%{_datadir}/lim/html/_opendnssec/enforcer_zone_list.html
%{_datadir}/lim/html/_opendnssec/hsm_info.html
%{_datadir}/lim/html/_opendnssec/signer_clear.html
%{_datadir}/lim/html/_opendnssec/signer_flush.html
%{_datadir}/lim/html/_opendnssec/signer_queue.html
%{_datadir}/lim/html/_opendnssec/signer_sign.html
%{_datadir}/lim/html/_opendnssec/signer_update.html
%{_datadir}/lim/html/_opendnssec/signer_zones.html
%{_datadir}/lim/html/_opendnssec/system_information.html


%changelog
* Wed Aug 07 2013 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.13-1
- Release 0.13
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora

