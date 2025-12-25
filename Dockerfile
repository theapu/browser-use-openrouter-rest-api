# Stage 1: Builder
FROM python:3.11.8-slim-bookworm AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app
COPY pyproject.toml .

RUN uv venv .venv && \
    uv sync

# Stage 2: Final Runtime
FROM python:3.11.8-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    # Set default display for X11
    DISPLAY=:99

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv

# Install Playwright browsers, system deps, AND GUI tools (Xvfb, VNC, Fluxbox)
# CHANGED: Added mkdir -p /root/.fluxbox to pre-create config directory
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    fluxbox \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.fluxbox

# Install chromium deps
RUN python -m playwright install chromium --with-deps && \
    rm -rf /var/lib/apt/lists/*

COPY main.py .
COPY start.sh .

# Make start script executable
RUN chmod +x start.sh

EXPOSE 8000 5900

# Use the start script to launch VNC + App
CMD ["./start.sh"]
