SUBDIRS = 
PROGRAMS = scheduler.sh hello-world.sh
INSTALLDIR = $(RESTAPIDIR)/cgi-bin

include ../../makefile.inc

clean: clean-default
build: build-default
lint: lint-default
test: test-default

# Programs are installed to the cgi-bin dir without a BINPREFIX or .sh extension
clean-install:
	for i in $(PROGRAMS) ; do \
		progname="$$(basename $$i .sh)" ; \
		rm -f "$(DESTDIR)$(INSTALLDIR)/$$progname" ; \
	done
install:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(INSTALLDIR)
	for i in $(PROGRAMS) ; do \
        progname="$$(basename $$i .sh)" ; \
        $(INSTALL) $$i "$(DESTDIR)$(INSTALLDIR)/$$progname" ; \
    done
