MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --quiet

all:        base
.PHONY: all base

base:
	@make --directory=$@
