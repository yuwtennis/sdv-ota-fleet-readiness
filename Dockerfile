# syntax=docker/dockerfile:1
FROM python:3.15-slim-trixie

RUN pip install uv

WORKDIR /app

ADD pyproject.toml .
ADD uv.lock .
ADD sdvotafleetreadiness/ sdvotafleetreadiness/
ADD scripts/ scripts/

RUN uv sync

ENTRYPOINT ["sh", "scripts/docker-entrypoint.sh"]