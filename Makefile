.PHONY: lint lint-ci

lint:
	uv run ruff format src
	uv run ruff check src --fix

lint-ci:
	uv run ruff check src
	uv run ruff format src --check

