.PHONY: integration lint test format

integration: lint test

lint:
	luacheck lua plugin

test:
	vusted lua plugin

format:
	stylua lua plugin
