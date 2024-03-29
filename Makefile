.DEFAULT_GOAL := all

.PHONY: all
all: test gen fmt

.PHONY: test
test:
	@cargo test --all

.PHONY: gen
gen:
	@tools/gen.sh

.PHONY: tidy
tidy:
	@tools/tidy.sh
