FROM python:3.11-slim

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Installer Poetry
RUN pip install poetry

# Copier les fichiers de dépendances
COPY pyproject.toml poetry.lock* ./

# Installer les dépendances sans créer de venv
RUN poetry config virtualenvs.create false && poetry install --no-interaction --no-ansi --no-root
# Copier le code source
COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]