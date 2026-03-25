srpm:
	mkdir -p /tmp/copr-srpm-build
	cp rpm/sklein-devbox.spec /tmp/copr-srpm-build/
	cp -r . /tmp/copr-srpm-build/sklein-devbox
	cd /tmp/copr-srpm-build && \
		tar -czf sklein-devbox.tar.gz --exclude='.git' --exclude='rpmbuild' sklein-devbox && \
		rpmbuild -bs sklein-devbox.spec \
			--define "_topdir /tmp/copr-srpm-build/rpmbuild" \
			--define "dist .fc42" \
			--define "_sourcedir /tmp/copr-srpm-build"
	cp /tmp/copr-srpm-build/rpmbuild/SRPMS/*.src.rpm $(outdir)
