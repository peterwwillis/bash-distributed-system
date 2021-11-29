SUBDIRS = 
PROGRAMS = processor.sh processor-logger-tee.sh scheduler.sh state.sh

include ../makefile.inc

clean: clean-default
clean-install:
	for i in $(PROGRAMS) ; do \
		progname="$$(basename $$i .sh)" ; \
		rm -f "$(DESTDIR)$(BINDIR)/$(BINPREFIX)$$progname" ; \
	done
build: build-default
lint: lint-default
test: test-default
	make -C tests test
install:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(BINDIR)
	for i in $(PROGRAMS) ; do \
        progname="$$(basename $$i .sh)" ; \
        $(INSTALL) $$i "$(DESTDIR)$(BINDIR)/$(BINPREFIX)$$progname" ; \
    done
