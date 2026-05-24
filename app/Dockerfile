FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim AS runtime

RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

COPY --from=builder /install /usr/local

# Elimina setuptools y wheel del runtime, no los necesitamos
# Solo son necesarios en build time
RUN pip uninstall -y setuptools wheel pip || true

COPY src/ ./src/

USER appuser

EXPOSE 8080

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
