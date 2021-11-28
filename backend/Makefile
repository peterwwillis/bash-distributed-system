.SUFFIXES: .m4 .sh

PROGRAMS = processor.sh scheduler.sh state.sh

include ../makefile.inc

clean:
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

