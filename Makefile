.PHONY: test vusted lint format

test: vusted lint

vusted:
	vusted .

lint:
	luacheck .

format:
	stylua .
