FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    NODE_MAJOR=22

# git: the cloud runtime clones and pushes repositories.
# Node + the Claude Code CLI: the `claude` worker engine spawns it headlessly
# (`claude -p ... --output-format stream-json`). Codex is optional; add
# `npm install -g @openai/codex` here if you run WORKER_ENGINE=codex.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential git curl ca-certificates gnupg \
    && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && apt-get purge -y --auto-remove gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements-dev.txt pyproject.toml ./
RUN pip install --no-cache-dir -r requirements-dev.txt

COPY . .

# The Claude CLI refuses to run with permissions bypassed as root, and cloned
# workspaces should not be root-owned either, so everything runs as `phodex`.
RUN useradd --create-home --uid 1000 phodex \
    && mkdir -p /srv/phodex/workspaces \
    && chown -R phodex:phodex /srv/phodex /app
USER phodex
ENV HOME=/home/phodex \
    WORKSPACES_ROOT=/srv/phodex/workspaces

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
