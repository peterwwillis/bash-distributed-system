# To install system-wide, use:
#
#     make PREFIX=/usr/local clean clean-install build test install
# 
# Otherwise the below defaults to installing to the current directory plus
# '_install'. This makes it easy to compile the applications and test them from
# the development environment. (NOTE: The installed files will have hard-coded
# paths so you can't just copy them somewhere else and run them)

#DESTDIR = 
PREFIX ?= $(shell pwd)/_install/usr

# Pass the above variables along to the rest of the Make processes
export

SUBDIRS = backend functions

all: build-default

include ./makefile.inc

clean: clean-default
clean-install: clean-install-default
build: build-default
test: test-default
install: install-default
