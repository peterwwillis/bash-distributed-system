PROGRAMS = scheduler.sh hello-world.sh
SUBDIRS = 
BINDIR = $(RESTAPIDIR)/cgi-bin

include ../../makefile.inc

build: build-default
test: test-default
clean: clean-default

# Programs are installed to the cgi-bin dir without a BINPREFIX or .sh extension
clean-install:
	for i in $(PROGRAMS) ; do \
		progname="$$(basename $$i .sh)" ; \
		rm -f "$(DESTDIR)$(BINDIR)/$$progname" ; \
	done
install:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(BINDIR)
	for i in $(PROGRAMS) ; do \
        progname="$$(basename $$i .sh)" ; \
        $(INSTALL) $$i "$(DESTDIR)$(BINDIR)/$$progname" ; \
    done
