SHELL := /usr/bin/env bash

.PHONY: check doctor install-deps build-drivers install-drivers build-control-center install-control-center install

check:
	./scripts/validate.sh

doctor:
	./scripts/doctor.sh

install-deps:
	./scripts/install-deps.sh

build-drivers:
	./scripts/build-drivers.sh

install-drivers:
	./scripts/install-drivers.sh

build-control-center:
	./scripts/build-control-center.sh

install-control-center:
	./scripts/install-control-center.sh

install: install-deps build-drivers install-drivers build-control-center install-control-center

