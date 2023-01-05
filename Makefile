# =====CONFIG=====
V_PATH ?= v
V := $(V_PATH) -showcc -d use_openssl

all: vdocker


# =====COMPILATION=====
.PHONY: vdocker
vdocker:
	$(V) -g -shared .

.PHONY: c
c:
	$(V) -o docker.c .


# =====DOCS=====
.PHONY: api-docs
api-docs:
	rm -rf '_docs'
	v doc -f html -m -readme .


# =====OTHER=====
.PHONY: lint
lint:
	$(V) fmt -verify .

.PHONY: fmt
fmt:
	$(V) fmt -w .
