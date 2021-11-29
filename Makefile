# To install system-wide, use:
#
#     make PREFIX=/usr/local clean clean-install build install test
# 
# The PREFIX defaults to the current directory plus '_install' so it's easier 
# to install and test the software in the local dev environment. Note that the
# installed files have hard-coded paths, so you can't just copy them somewhere
# and run them. This is also why 'install' is run before 'test' (otherwise
# we'd need to hard-code the paths to the local dev environment, test them,
# then hard-code the paths again before installing)

#DESTDIR = 
PREFIX ?= $(shell pwd)/_install/usr

# Pass the above variables along to the rest of the Make processes
export

SUBDIRS = backend functions rest-api

all: build-default

include ./makefile.inc

clean: clean-default
clean-install: clean-install-default
build: build-default
test: test-default
install: install-default
