# vim: syntax=make

INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 0755

# Path defaults
PREFIX ?= /usr/local
EXEC_PREFIX ?= $(PREFIX)
BINDIR ?= $(EXEC_PREFIX)/bin
LIBDIR ?= $(EXEC_PREFIX)/lib

# The prefix added to the installed programs
BINPREFIX ?= shds-
# The directory where the 'functions/' library will be installed
FUNCTIONSDIR=$(LIBDIR)/shds/functions
# The directory where the cgi-bin apps will be installed
RESTAPIDIR=$(LIBDIR)/shds/rest-api

BIN_STATE ?= $(BINPREFIX)state
BIN_PROCESSOR ?= $(BINPREFIX)processor
BIN_SCHEDULER ?= $(BINPREFIX)scheduler

# Macros for m4 to replace in scripts
M4_ARGS := -D_PREFIX_=$(PREFIX) -D_EXEC_PREFIX=$(EXEC_PREFIX) \
    -D_BINDIR_=$(BINDIR) -D_LIBDIR_=$(LIBDIR) -D_FUNCTIONSDIR_=$(FUNCTIONSDIR) -D_RESTAPIDIR_=$(RESTAPIDIR) \
    -D_BINPREFIX_=$(BINPREFIX) \
    -D_BIN_STATE_=$(BIN_STATE) -D_BIN_PROCESSOR_=$(BIN_PROCESSOR) -D_BIN_SCHEDULER_=$(BIN_SCHEDULER)

PATH := $(PATH):$(DESTDIR)$(BINDIR)
export PATH

INSTALLDIR ?= $(BINDIR)

##################################################################################

.PHONY: all all-default build build-default clean clean-default clean-install clean-install-default lint lint-default install install-default test test-default

.SUFFIXES: .m4 .sh

all-default: $(PROGRAMS)

build-default: $(PROGRAMS)
	set -ex; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i build ; done ; fi

clean-default:
	for i in $(PROGRAMS) ; do rm -f "$$i" ; done
	set -ex; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i clean ; done ; fi

lint-default: $(PROGRAMS)
	set -ex; for i in $(PROGRAMS) ; do shellcheck -x $$i ; done
	set -ex; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i lint ; done ; fi

clean-install-default:
	for i in $(PROGRAMS) ; do rm -f "$(DESTDIR)$(INSTALLDIR)/$$i" ; done
	set -e; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i clean-install ; done ; fi

install-default:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(INSTALLDIR)
	set -ex; for i in $(PROGRAMS) ; do $(INSTALL) -m 0755 $$i "$(DESTDIR)$(INSTALLDIR)/$$i" ; done
	set -ex; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i install ; done ; fi

%.sh: %.m4
	m4 $(M4_ARGS) -P <'$<' >'$@'

test-default: lint-default
	set -ex; if [ -n "$(SUBDIRS)" ] ; then for i in $(SUBDIRS) ; do make -C $$i test ; done ; fi

%: %-default
	@	true
