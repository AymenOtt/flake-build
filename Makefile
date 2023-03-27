.DEFAULT_GOAL := build

PREFIX ?= /usr
BINDIR ?= ${PREFIX}/bin
SHAREDIR ?= ${PREFIX}/share/oci-pilot
FLAKEDIR ?= ${PREFIX}/share/flakes
TEMPLATEDIR ?= /etc/flakes

.PHONY: package
package: clean vendor sourcetar
	rm -rf package/build
	mkdir -p package/build
	gzip package/oci-pilot.tar
	mv package/oci-pilot.tar.gz package/build
	cp package/oci-pilot.spec package/build
	cp package/cargo_config package/build
	# update changelog using reference file
	helper/update_changelog.py --since package/oci-pilot.changes.ref > \
		package/build/oci-pilot.changes
	helper/update_changelog.py --file package/oci-pilot.changes.ref >> \
		package/build/oci-pilot.changes
	@echo "Find package data at package/build"

vendor:
	(cd oci-pilot && cargo vendor)
	(cd oci-ctl && cargo vendor)

sourcetar:
	rm -rf package/oci-pilot
	mkdir package/oci-pilot
	cp Makefile package/oci-pilot
	cp -a oci-pilot package/oci-pilot/
	cp -a oci-ctl package/oci-pilot/
	cp -a doc package/oci-pilot/
	tar -C package -cf package/oci-pilot.tar oci-pilot
	rm -rf package/oci-pilot

.PHONY:build
build: man
	cd oci-pilot && cargo build -v --release && upx --best --lzma target/release/oci-pilot
	cd oci-ctl && cargo build -v --release && upx --best --lzma target/release/oci-ctl

clean:
	cd oci-pilot && cargo -v clean
	cd oci-ctl && cargo -v clean
	rm -rf oci-pilot/vendor
	rm -rf oci-ctl/vendor
	${MAKE} -C doc clean

test:
	cd oci-pilot && cargo -v build
	cd oci-pilot && cargo -v test

install:
	install -d -m 755 $(DESTDIR)$(BINDIR)
	install -d -m 755 $(DESTDIR)$(SHAREDIR)
	install -d -m 755 $(DESTDIR)$(TEMPLATEDIR)
	install -d -m 755 $(DESTDIR)$(FLAKEDIR)
	install -d -m 755 ${DESTDIR}usr/share/man/man8
	install -m 755 oci-pilot/target/release/oci-pilot \
		$(DESTDIR)$(BINDIR)/oci-pilot
	install -m 755 oci-ctl/target/release/oci-ctl \
		$(DESTDIR)$(BINDIR)/oci-ctl
	install -m 755 oci-ctl/debbuild/oci-deb \
		$(DESTDIR)$(BINDIR)/oci-deb
	install -m 644 oci-ctl/debbuild/container.spec.in \
		$(DESTDIR)$(SHAREDIR)/container.spec.in
	install -m 644 oci-ctl/template/container-flake.yaml \
		$(DESTDIR)$(TEMPLATEDIR)/container-flake.yaml
	install -m 644 doc/*.8 ${DESTDIR}usr/share/man/man8

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/oci-*

man:
	${MAKE} -C doc man
