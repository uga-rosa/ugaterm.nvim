.PHONY: integration lint test format

integration: lint test

lint:
	luacheck .

test:
	vusted .

format:
	stylua .
