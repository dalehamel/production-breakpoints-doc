SHELL=/bin/bash -o pipefail

DOCKER ?= docker

.DEFAULT_GOAL := all

PANDOC_BUILDER_IMAGE ?= "quay.io/dalehamel/pandoc-report-builder"
PWD ?= `pwd`

clean:
	rm -rf output
	rm -f index.html

.PHONY: doc/build
doc/build:
	${DOCKER} run --user `id -u`:`id -g` -v ${PWD}:/app ${PANDOC_BUILDER_IMAGE} /app/scripts/pandoc-build $(FORMATS)

# If docx is shared, this can be used for diffing markdown representation
# of the docx export before and after modifications. Useful for google sharing
output/doc.md:
	${DOCKER} run --user `id -u`:`id -g` -v ${PWD}:/app ${PANDOC_BUILDER_IMAGE} pandoc doc.docx -o output/doc.md

index.html:
	ln -sf output/doc.html index.html

.PHONY: quirks
quirks:
	scripts/tidy

.PHONY: plain
plain:
	${DOCKER} run --user `id -u`:`id -g` -v ${PWD}:/app ${PANDOC_BUILDER_IMAGE} /app/scripts/pandoc-build plain

.PHONY: audio
audio: plain
	${DOCKER} run --user `id -u`:`id -g` -v ${PWD}:/app ${PANDOC_BUILDER_IMAGE} /app/scripts/make-audio

.PHONY: outputs
outputs: doc/build index.html

all: audio outputs
