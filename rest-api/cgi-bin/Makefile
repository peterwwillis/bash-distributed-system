SUBDIRS = 
PROGRAMS = scheduler.sh hello-world.sh
INSTALLDIR = $(RESTAPIDIR)/cgi-bin

include ../../makefile.inc

build: build-default
test: test-default
clean: clean-default

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
