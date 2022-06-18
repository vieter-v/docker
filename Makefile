# =====CONFIG=====
V_PATH ?= v
V := $(V_PATH) -showcc

all: vdocker


# =====COMPILATION=====
.PHONY: vdocker
vdocker:
	$(V) -g -shared .


# =====DOCS=====
.PHONY: api-docs
api-docs:
	rm -rf '_docs'
	v doc -f html -m -readme .


# =====OTHER=====
.PHONY: lint
lint:
	$(V) fmt -verify .
	$(V) vet -W .
	$(V_PATH) missdoc -p .
	@ [ $$($(V_PATH) missdoc -p . | wc -l) = 0 ]

.PHONY: fmt
fmt:
	$(V) fmt -w .
