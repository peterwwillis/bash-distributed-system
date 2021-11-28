# Default to installing to the current directory plus '_install'.
# This makes it easy to compile the applications and test them from the
# development environment by default.
# NOTE: The installed files will have hard-coded paths, so you can't 
# just copy them somewhere else and run them.
#DESTDIR = $(shell pwd)/_install
PREFIX = $(shell pwd)/_install/usr

# Pass the above variables along to the rest of the Make processes
export

include makefile.inc

all: build

test: backend_test
	@echo done 'make test'

backend_test:
	make -C backend test

build:
	make -C backend build
	make -C functions build

install: build
	make -C functions install
	make -C backend install

clean:
	make -C backend clean
	make -C functions clean

clean-install:
	make -C backend clean-install
	make -C functions clean-install
