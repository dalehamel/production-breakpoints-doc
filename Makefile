SHELL=/bin/bash -o pipefail

DOCKER ?= docker

.DEFAULT_GOAL := all

PANDOC_BUILDER_IMAGE ?= "quay.io/dalehamel/pandoc-report-builder"
PWD ?= `pwd`

.PHONY: doc/build
doc/build:
	${DOCKER} run -v ${PWD}:/app ${PANDOC_BUILDER_IMAGE} /app/scripts/pandoc-build

all: doc/build
