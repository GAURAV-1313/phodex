.PHONY: install run test lint format migrate

install:
	pip install -r requirements-dev.txt

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	PYTHONPATH=. pytest -q

lint:
	ruff check .
	mypy app

format:
	ruff format .

migrate:
	alembic upgrade head
