%global debug_package %{nil}
%define fullver 0.0.0

Name:           sklein-devbox
Version:        0.0.0
Release:        1%{?dist}
Summary:        CLI to manage Stéphane Klein development environment powered by Podman container

License:        MIT
URL:            https://github.com/stephane-klein/sklein-devbox
Source0:        sklein-devbox-%{version}.tar.gz

BuildRequires:  golang >= 1.25
BuildRequires:  git
Requires:       podman

%description
sklein-devbox cli manage containerized development environment using Podman.
It provides a portable and reproducible development environment based on Fedora.

%prep
%autosetup -n sklein-devbox-%{version}

%build
export GOPATH=%{_topdir}/../go
export GOBIN=%{_builddir}/sklein-devbox/bin
go build \
    -buildmode pie \
    -ldflags "-linkmode=external -extldflags '%__global_ldflags' -X main.version=%{fullver}" \
    -o sklein-devbox ./cmd

%install
install -D -p -m 0755 sklein-devbox %{buildroot}%{_bindir}/sklein-devbox

%files
%{_bindir}/sklein-devbox

%changelog
* Wed Mar 18 2026 Stéphane Klein <contact@stephane-klein.info> - 20260318.1.0-1
- Initial package
