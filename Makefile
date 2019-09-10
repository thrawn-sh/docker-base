MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

include Makefile.options

build: .$(DISTRIBUTION)-$(SNAPSHOT).image

.$(DISTRIBUTION)-$(SNAPSHOT).image: Dockerfile Makefile Makefile.options
	@echo [docker] shadowhunt/base
	@docker build                                           \
		--build-arg "DISTRIBUTION=$(DISTRIBUTION)"          \
		--build-arg "SNAPSHOT=$(SNAPSHOT)"                  \
		--compress                                          \
		--force-rm                                          \
		--pull                                              \
		--quiet                                             \
		--tag "shadowhunt/base:$(DISTRIBUTION)-$(SNAPSHOT)" \
		.
	@docker push "shadowhunt/base:$(DISTRIBUTION)-$(SNAPSHOT)"
	@docker images --all --filter "dangling=true" --quiet --no-trunc | xargs --no-run-if-empty docker rmi --force
	@echo $(BUILD_DATE) > $@

.PHONY: build
