# Makefile for COPR builds
# Usage: make [target]

version = $(shell git describe --tags --abbrev=0 2>/dev/null | cut -d'-' -f1 || echo "0.0.0")
commit_sha = $(shell git rev-parse --short HEAD 2>/dev/null)
outdir = .

.PHONY: srpm

srpm:
	dnf install -y git golang rpm-build rpmdevtools
	mkdir -p ~/rpmbuild/SOURCES
	git archive \
		--format tar.gz \
		--prefix sklein-devbox-$(version)/ \
		--output ~/rpmbuild/SOURCES/sklein-devbox-$(version).tar.gz \
		HEAD
	rpmbuild -bs \
		--define "version $(version)" \
		--define "fullver $(version)-$(commit_sha)" \
		--define "_srcrpmdir $(outdir)" \
		--define "_topdir ~/rpmbuild" \
		rpm/sklein-devbox.spec
