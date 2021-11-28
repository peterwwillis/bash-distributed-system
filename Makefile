# Default to installing to the current directory plus '_install'.
# This makes it easy to compile the applications and test them from the
# development environment by default.
# NOTE: The installed files will have hard-coded paths, so you can't 
# just copy them somewhere else and run them.
#DESTDIR = $(shell pwd)/_install
PREFIX = $(shell pwd)/_install/usr
# Pass the above variables along to the rest of the Make processes
export

SUBDIRS = backend functions

all: build-default

include ./makefile.inc

test: backend_test
	@echo done 'make test'

backend_test:
	make -C backend test

build: build-default
install: install-default
clean: clean-default

clean-install: clean-install-default
	find $(PREFIX) -type d -exec rmdir -p {} \; || true

