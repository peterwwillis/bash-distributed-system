.SUFFIXES: .m4 .sh

PROGRAMS = functions.sh main.sh
BINDIR = $(FUNCTIONSDIR)

include ../makefile.inc

clean: clean-default
	make -C processor clean
	make -C state clean

install: install-default
	make -C processor install
	make -C state install

