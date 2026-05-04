# BP Monitor — Feuille de route

Microservice de suivi de tension artérielle · Clean Architecture · FastAPI

---

## Règle fondamentale

> Chaque couche ne connaît que les couches plus internes — jamais l'inverse.
> `Interfaces → Application → Domain → Core`
> `Infrastructure → Domain → Core`

---

## Étape 1 — Structure du projet & Clean Architecture

> Arborescence des dossiers, couches, dépendances

- Initialiser le projet FastAPI avec `Poetry`
- Créer l'arborescence Clean Architecture (`core / domain / application / infrastructure / interfaces`)
- Configurer les fichiers de base : `pyproject.toml`, `.env`, `Dockerfile`
- Mettre en place les règles de dépendance entre couches

---

## Étape 2 — Couche Core

> Base Entity, Value Objects primitifs, Exceptions

- `BaseEntity`, `AggregateRoot`, `ValueObject`
- Exceptions métier globales (`DomainException`, `NotFoundError`, `ValidationError`...)
- Interfaces / protocols partagés (`Repository`, `UnitOfWork`)

---

## Étape 3 — Couche Domain

> Entités métier, Value Objects, règles BP

- Entités : `Measurement`, `Patient`, `Doctor`, `Alert`
- Value Objects : `BloodPressure`, `Threshold`, `BPCategory`
- Domain services : `BPAnalyzer`, `AverageCalculator`
- Interfaces des repositories (`IMeasurementRepository`, `IPatientRepository`...)

---

## Étape 4 — Couche Application

> Use Cases, DTOs, orchestration

- Use Cases : `CreateMeasurement`, `GetBPSummary`, `TriggerAlert`
- DTOs : `MeasurementDTO`, `AlertDTO`, `SummaryDTO`
- Application services & event handlers

---

## Étape 5 — Couche Infrastructure

> DB, cache, notifications, JWT

- PostgreSQL avec SQLAlchemy + Alembic migrations
- Implémentation des repositories (`SQLMeasurementRepository`...)
- Redis pour cache & alertes temps réel
- Adaptateurs notifications : Twilio SMS, FCM Push
- JWT Auth service (mode standalone + mode intégré Vitoo Santé)

---

## Étape 6 — Couche Interfaces

> FastAPI routes, schemas, middlewares

- Routers FastAPI : `/measurements`, `/patients`, `/alerts`, `/auth`
- Schemas Pydantic (request / response)
- Middlewares : auth JWT, CORS, error handler global
- Dependency Injection (FastAPI `Depends`)

---

## Étape 7 — Docker & Déploiement

> Containerisation, docker-compose, CI/CD

- Dockerfile optimisé (multi-stage)
- `docker-compose.yml` : API + PostgreSQL + Redis
- Variables d'environnement & secrets
- Tests + pipeline CI/CD basique

---

Parfait ! Maintenant on attaque le vrai code. On suit votre architecture dans l'ordre :

---

## Rappel de votre structure

```
app/
├── core/                  ← on commence ici
├── domain/
│   ├── entities/
│   ├── enums/
│   ├── repositories/
│   └── services/
├── application/
│   ├── repositories/
│   ├── services/
│   ├── use_cases/
│   └── dtos/
├── infrastructure/
│   ├── db/
│   ├── models/
│   ├── repositories/
│   └── notifications/
├── interfaces/
│   ├── routes/
│   └── schemas/
└── main.py
```

---

## Par quoi on commence ?

**1 → Couche `core`** — `BaseEntity`, `ValueObject`, `exceptions`, `config`

**2 → Couche `domain`** — entités BP, enums, interfaces repositories

**3 → Couche `infrastructure`** — DB, models, AuditableEntity

**4 → Couche `application`** — use cases, DTOs, services

**5 → Couche `interfaces`** — routes FastAPI, schemas

**6 → `main.py` + Docker** — on lance tout

---
docker-compose up --build
docker-compose exec api alembic init alembic
docker-compose exec api alembic revision --autogenerate -m "initial migration"