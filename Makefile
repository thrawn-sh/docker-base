MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

FILES     := $(shell find root -type f)

include Makefile.options

build: .$(SNAPSHOT).image

clean:
	@echo "[clean] dangling images"
	@docker images --all --filter "dangling=true" --quiet --no-trunc | xargs --no-run-if-empty docker rmi --force

push: build
	@echo " [push] shadowhunt/$(IMAGE):$(SNAPSHOT)"
	@docker push "shadowhunt/$(IMAGE):$(SNAPSHOT)"
	@docker push "shadowhunt/$(IMAGE):latest"

.$(SNAPSHOT).image: Dockerfile Makefile Makefile.options $(FILES)
	@echo "[build] shadowhunt/$(IMAGE):$(SNAPSHOT)"
	@docker build                               \
		--build-arg "SNAPSHOT=$(SNAPSHOT)"      \
		--compress                              \
		--force-rm                              \
		--pull                                  \
		--tag "shadowhunt/$(IMAGE):$(SNAPSHOT)" \
		--tag "shadowhunt/$(IMAGE):latest"      \
		.
	@echo "$(BUILD_DATE)" > $@

.PHONY: build clean push
