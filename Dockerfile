#BUILD STAGE

#Use Python 3.12 base image
FROM python:3.12 AS builder
#Set working directory
WORKDIR /app
#Install uv package manager
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
#Copy pyproject.toml
COPY pyproject.toml pyproject.toml
COPY README.md README.md

#Install Python dependencies using uv into a virtual environment
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"
COPY . .
RUN uv sync

#FINAL STAGE

#Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim
WORKDIR /app
#Copy the virtual environment from build stage
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
#Copy application source code
COPY --from=builder /app /app
#Create non-root user for security
RUN groupadd -g 1000 appuser && useradd -m -u 1000 -g appuser appuser && chown -R appuser:appuser /app
USER appuser
#Expose port 8000
EXPOSE 8000
#Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]