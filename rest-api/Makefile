PROGRAMS = bash-cgi.sh cgi-svc-wrapper.sh webserver.sh
SUBDIRS = cgi-bin
BINDIR = $(RESTAPIDIR)

include ../makefile.inc

build: build-default
test: test-default
clean: clean-default

# Programs are installed to the rest-api dir without a BINPREFIX
clean-install:
	for i in $(PROGRAMS) ; do rm -f "$(DESTDIR)$(BINDIR)/$$i" ; done
install:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(BINDIR)
	for i in $(PROGRAMS) ; do $(INSTALL) $$i "$(DESTDIR)$(BINDIR)/$$i" ; done
