# GTINFinder - Setup Guide

## 🚀 Quick Start

Dit document beschrijft hoe je de GTINFinder development environment opzet.

## 📋 Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Make (optioneel)

## 🔧 Setup Process

### 1. Clone Repository
```bash
git clone <repository-url>
cd GTINFinder
```

### 2. Run Setup
```bash
make setup
```

De setup script:
- Genereert secure keys
- Creëert `.env` bestand
- Start alle services
- Initialiseert databases
- Creëert admin users

### 3. Start Services
```bash
make up
```

## 🔐 Login Credentials

Na succesvolle setup zijn de services beschikbaar op:

### Directus (Headless CMS)
- **URL**: http://localhost:8055
- **Email**: admin@example.com
- **Password**: admin123

### Airflow (Orchestration)
- **URL**: http://localhost:8080
- **Username**: admin
- **Password**: *Automatisch gegenereerd*

**Wachtwoord vinden**:
```bash
docker-compose logs airflow | grep "Password for user 'admin'"
```

### Authentik (SSO/OIDC)
- **URL**: http://localhost:9000
- **Username**: akadmin
- **Password**: admin123

### Frontend (React App)
- **URL**: http://localhost:3000
- **Login**: Via Authentik SSO

## 🏗️ Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   Directus      │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (Headless CMS)│◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   Airflow       │
                        │   (Orchestration)│
                        └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   Authentik     │
                        │   (SSO/OIDC)    │
                        └─────────────────┘
```

## 📁 Project Structure

```
gtin-finder/
├── docker-compose.yml          # Service orchestration
├── .env                     # Environment variables
├── Makefile                 # Convenience commands
├── setup.sh                 # Initial setup script
├── frontend/                 # React application
│   ├── src/
│   ├── public/
│   └── package.json
├── airflow/                  # Airflow DAGs & config
│   ├── dags/
│   └── airflow.cfg
├── database/                 # Database initialization
│   └── init.sql
├── nginx/                    # Reverse proxy config
└── docs/                     # Documentation
    ├── setup-guide.md         # Dit document
    └── v1.0-project-plan.md  # Project architecture
```

## 🛠️ Development Workflow

### 1. Development
```bash
# Start alle services
make up

# Start specifieke services
make up-postgres
make up-directus
make up-airflow
```

### 2. Logs Bekijken
```bash
# Bekijk logs van alle services
docker-compose logs

# Bekijk specifieke service logs
docker-compose logs airflow
docker-compose logs directus
docker-compose logs postgres
```

### 3. Database Toegang
```bash
# PostgreSQL
docker-compose exec postgres psql -U postgres -d gtin_finder

# Directus database
docker-compose exec postgres psql -U directus_user -d directus
```

### 4. Airflow Management
```bash
# Voer commando's uit in Airflow container
docker-compose exec airflow bash

# DAG lijst bekijken
docker-compose exec airflow airflow dags list

# DAG triggeren
docker-compose exec airflow airflow dags trigger gtin_validator_dag
```

## 🔧 Troubleshooting

### Airflow Login Problemen
Als je niet kunt inloggen op Airflow:

1. **Check generated wachtwoord**:
   ```bash
   docker-compose logs airflow | grep "Password for user 'admin'"
   ```

2. **Reset Airflow**:
   ```bash
   docker-compose down
   docker volume rm gtinfinder_airflow_logs
   make up
   ```

### Database Connectie Problemen
```bash
# Check database status
docker-compose ps

# Check PostgreSQL logs
docker-compose logs postgres
```

### Service Start Problemen
```bash
# Complete reset
docker-compose down --volumes --remove-orphans
make setup
```

## 📚 Documentatie

- **Project Architectuur**: Zie `docs/v1.0-project-plan.md`
- **Sprint Planning**: Zie `docs/sprint-*` directories
- **Technical Tasks**: Zie `docs/sprint-*/technical-tasks.md`

## 🔄 Updates

### Environment Variables Updaten
```bash
# Genereer nieuwe keys
make setup

# Of handmatig .env aanpassen
vim .env
```

### Services Herstarten
```bash
# Volledige herstart
docker-compose restart

# Specifieke service herstarten
docker-compose restart airflow
```

## 📞 Support

Bij problemen:
1. Check dit document
2. Check service logs
3. Draai `make setup` opnieuw
4. Contact project team

---

**Document Status**: ACTIEF - Laatste update: ${CURRENT_DATE}  
**Versie**: 1.0
