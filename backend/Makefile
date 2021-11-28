PROGRAMS = processor.sh scheduler.sh state.sh
SUBDIRS = 

include ../makefile.inc

all: all-default
build: build-default
clean: clean-default
clean-install:
	for i in $(PROGRAMS) ; do \
		progname="$$(basename $$i .sh)" ; \
		rm -f "$(DESTDIR)$(BINDIR)/$(BINPREFIX)$$progname" ; \
	done
install:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(BINDIR)
	for i in $(PROGRAMS) ; do \
        progname="$$(basename $$i .sh)" ; \
        $(INSTALL) $$i "$(DESTDIR)$(BINDIR)/$(BINPREFIX)$$progname" ; \
    done
