MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

FILES     := $(shell find root -type f)A

include Makefile.options

build: .$(SNAPSHOT).image

.$(SNAPSHOT).image: Dockerfile Makefile Makefile.options $(FILES)
	@echo [docker] shadowhunt/base
	@docker build                           \
		--build-arg "SNAPSHOT=$(SNAPSHOT)"  \
		--compress                          \
		--force-rm                          \
		--pull                              \
		--tag "shadowhunt/base:$(SNAPSHOT)" \
		--tag "shadowhunt/base:latest"      \
		.
	@docker push "shadowhunt/base:$(SNAPSHOT)"
	@docker push "shadowhunt/base:latest"
	@docker images --all --filter "dangling=true" --quiet --no-trunc | xargs --no-run-if-empty docker rmi --force
	@echo $(BUILD_DATE) > $@

.PHONY: build
