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

# Last thing's first
M4_ARGS := -D_PREFIX_=$(PREFIX) -D_EXEC_PREFIX=$(EXEC_PREFIX) -D_BINDIR_=$(BINDIR) \
    -D_LIBDIR_=$(LIBDIR) -D_FUNCTIONSDIR_=$(FUNCTIONSDIR)

PATH := $(PATH):$(DESTDIR)$(BINDIR)
export PATH

##################################################################################

.PHONY: all clean lint install test

ifdef PROGRAMS

all-default: $(PROGRAMS)

clean-default: clean-install-default
	for i in $(PROGRAMS) ; do rm -f "$$i" ; done

lint-default: $(PROGRAMS)
	true
	#for i in $(PROGRAMS) ; do shellcheck $$i ; done

clean-install-default:
	for i in $(PROGRAMS) ; do rm -f "$(DESTDIR)$(BINDIR)/$$i" ; done

install-default:
	$(INSTALL) -d -m 0755 $(DESTDIR)$(BINDIR)
	for i in $(PROGRAMS) ; do \
        $(INSTALL) $$i "$(DESTDIR)$(BINDIR)/$$i" ; \
    done

endif

%.sh: %.m4
	m4 $(M4_ARGS) -P <'$<' >'$@'

test-default: lint
	make -C tests

%: %-default
	@true
