.PHONY: install run test lint format migrate

install:
	python3.11 -m pip install -r requirements-dev.txt

run:
	python3.11 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	python3.11 -m pytest -q

lint:
	python3.11 -m ruff check .
	python3.11 -m mypy app

format:
	python3.11 -m ruff format .

migrate:
	python3.11 -m alembic upgrade head
