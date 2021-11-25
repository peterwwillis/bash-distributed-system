test: backend_test
	@echo done 'make test'

backend_test:
	make -C backend test
