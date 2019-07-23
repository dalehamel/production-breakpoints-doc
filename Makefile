SHELL=/bin/bash -o pipefail

DOCKER ?= docker

.DEFAULT_GOAL := all

PANDOC_BUILDER_IMAGE ?= "quay.io/dalehamel/pandoc-report-builder"
DOCKER_BUILDER ?= "pandoc-report-builder"
PWD ?= `pwd`

.PHONY: clean
clean:
	docker rm -f ${DOCKER_BUILDER} || true

.PHONY: _doc/builder/run
_doc/builder/run: clean
	${DOCKER} run -v ${PWD}:/app \
           --name ${DOCKER_BUILDER} \
           -d ${PANDOC_BUILDER_IMAGE} \
           /bin/sh -c 'sleep infinity'

.PHONY: doc/build
doc/build: _doc/builder/run
	${DOCKER} exec ${DOCKER_BUILDER} /app/scripts/pandoc-build

all: doc/build
