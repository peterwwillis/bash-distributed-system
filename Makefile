#DESTDIR = $(shell pwd)/_install
PREFIX = $(shell pwd)/_install/usr
export

all: build

test: backend_test
	@echo done 'make test'

backend_test:
	make -C backend test

build:
	make -C backend

install: build
	make -C functions install
	make -C backend install

clean:
	make -C backend clean
	make -C functions clean

include makefile.inc
