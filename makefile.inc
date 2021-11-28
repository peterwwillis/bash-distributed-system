INSTALL=install
INSTALL_PROGRAM=$(INSTALL) -m 0755

# Path defaults
PREFIX=/usr/local
EXEC_PREFIX=$(PREFIX)
BINDIR=$(EXEC_PREFIX)/bin
LIBDIR=$(EXEC_PREFIX)/lib

BINPREFIX=shds-

# Program-specific variables
FUNCTIONSDIR=$(LIBDIR)/functions

# Last thing's first
M4_ARGS=-D_PREFIX_=$(PREFIX) -D_EXEC_PREFIX=$(EXEC_PREFIX) -D_BINDIR_=$(BINDIR) \
    -D_LIBDIR_=$(LIBDIR) -D_FUNCTIONSDIR_=$(FUNCTIONSDIR)


##################################################################################

all: $(PROGRAMS)

clean:
	for i in $(PROGRAMS) ; do rm "$$i" ; done

lint: $(PROGRAMS)
	for i in $(PROGRAMS) ; do shellcheck $$i ; done

%.sh: %.m4
	m4 $(M4_ARGS) -P <'$<' >'$@'

test: lint
	make -C tests

install:
	for i in $(PROGRAMS) ; do $(INSTALL) $$i $(DESTDIR)$(BINDIR)/$(BINPREFIX)$$i
