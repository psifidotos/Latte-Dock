Name:           Latte-Dock
Version:        0.6.0
Release:        1%{?dist}
Summary:        Latte is a dock based on plasma frameworks

License:        GPLv2+
URL:            https://github.com/psifidotos/Latte-Dock
Source0:        https://github.com/psifidotos/Latte-Dock/archive/v%{version}.tar.gz

BuildRequires:  extra-cmake-modules
BuildRequires:  kf5-karchive-devel
BuildRequires:  kf5-kactivities-devel
BuildRequires:  kf5-kcoreaddons-devel
BuildRequires:  kf5-kdbusaddons-devel
BuildRequires:  kf5-kdeclarative-devel
BuildRequires:  kf5-knotifications-devel
BuildRequires:  kf5-kiconthemes-devel
BuildRequires:  kf5-ki18n-devel
BuildRequires:  kf5-kpackage-devel
BuildRequires:  kf5-plasma-devel
BuildRequires:  kf5-kwayland-devel
BuildRequires:  kf5-kwindowsystem-devel
BuildRequires:  kf5-kxmlgui-devel

%description
Latte is a dock based on plasma frameworks that provides an elegant and intuitive
experience for your tasks and plasmoids. It animates its contents by using
parabolic zoom effect and trys to be there only when it is needed.

"Art in Coffee"

%prep
%setup -q

%build
%{__mkdir_p} build
pushd build
%{cmake_kf5} DCMAKE_INSTALL_PREFIX=%{_usr} -DCMAKE_BUILD_TYPE=Release ..
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} install DESTDIR=$RPM_BUILD_ROOT -C build

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/latte-dock
%{_kf5_qmldir}/*
%{_datarootdir}/*

%changelog
* Fri Apr 6 2017 Marc Deop <marc@marcdeop.com> 0.6.0-1
- Initial package.

