# ================================
# STAGE 1: builder
# Instala dependencias en un entorno limpio
# ================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Copiamos solo requirements primero
# Docker cachea esta capa si requirements.txt no cambia
# Evita reinstalar todo cada vez que cambias código
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ================================
# STAGE 2: runtime
# Imagen final mínima, sin herramientas de build
# ================================
FROM python:3.11-slim AS runtime

# Usuario no root por seguridad
# Nunca corras contenedores como root en producción
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copiamos las dependencias instaladas del stage anterior
COPY --from=builder /install /usr/local

# Copiamos el código fuente
COPY src/ ./src/

# Cambiamos al usuario no root
USER appuser

# Puerto que expone la app
EXPOSE 8080

# Comando de arranque
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
