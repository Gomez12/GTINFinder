# GTINFinder

GTINFinder is een advanced GTIN (barcode) data enrichment platform die meerdere API bronnen combineert met AI-powered "golden record" creatie.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- Git

### Setup

1. **Clone repository**
```bash
git clone <repository-url>
cd gtin-finder
```

2. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env met je waarden
```

3. **Generate secure keys**
```bash
# Genereer Directus key (32 characters min)
openssl rand -base64 32

# Genereer Directus secret (32 characters min)
openssl rand -base64 32

# Genereer Airflow Fernet key
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Genereer Authentik secret key (50 characters min)
openssl rand -base64 50
```

4. **Start backend services**
```bash
docker-compose up -d
```

5. **Setup frontend**
```bash
cd frontend
npm install
npm run dev
```

### Access Points
- **Frontend:** http://localhost:3000
- **Directus Admin:** http://localhost:8055
- **Airflow:** http://localhost:8080
- **Authentik:** http://localhost:9000
- **Nginx Health:** http://localhost/health

### Initial Setup

#### Directus Admin Account
1. Ga naar http://localhost:8055
2. Login met:
   - Email: `admin@example.com`
   - Password: `admin123`
3. Configureer de collections

#### Airflow Admin Account
1. Ga naar http://localhost:8080
2. Login met:
   - Username: `airflow_user`
   - Password: `airflow_secure_password`

#### Authentik Setup
1. Ga naar http://localhost:9000
2. Login met:
   - Username: `akadmin`
   - Password: `admin123`
3. Configureer OIDC provider voor GTINFinder

### 📋 Default Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Directus | http://localhost:8055 | admin@example.com | admin123 |
| Airflow | http://localhost:8080 | airflow_user | airflow_secure_password |
| Authentik | http://localhost:9000 | akadmin | admin123 |
| PostgreSQL | localhost:5432 | postgres | (from .env) |

## 📋 Environment Variables

Kopieer `.env.example` naar `.env` en vul de volgende variabelen in:

### Database
```bash
POSTGRES_DB=gtin_finder
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
```

### Directus
```bash
DIRECTUS_KEY=your_directus_key_here_32_chars_min
DIRECTUS_SECRET=your_directus_secret_here_32_chars_min
DIRECTUS_DB=directus
DIRECTUS_USER=directus_user
DIRECTUS_PASSWORD=directus_secure_password
```

### Airflow
```bash
AIRFLOW_DB=airflow
AIRFLOW_USER=airflow_user
AIRFLOW_PASSWORD=airflow_secure_password
AIRFLOW_FERNET_KEY=your_fernet_key_here_32_chars
```

### Authentik
```bash
AUTHENTIK_SECRET_KEY=your_authentik_secret_key_here_50_chars_min
AUTHENTIK_DB=authentik
AUTHENTIK_USER=authentik_user
AUTHENTIK_PASSWORD=authentik_secure_password
```

## 🏗️ Project Structure

```
gtin-finder/
├── docker-compose.yml          # Docker services configuration
├── .env.example              # Environment variables template
├── database/                  # Database initialization scripts
│   └── init.sql             # PostgreSQL setup
├── airflow/                   # Airflow DAGs and configuration
│   └── dags/                # DAG files
├── nginx/                     # Nginx configuration
│   ├── nginx.conf            # Main nginx config
│   └── conf.d/              # Site configurations
├── frontend/                  # React frontend application
│   ├── src/                 # Source code
│   ├── public/              # Static assets
│   └── package.json         # Dependencies
├── docs/                      # Documentation
│   ├── v1.0-project-plan.md # Technical specifications
│   ├── sprint-planning.md    # Sprint planning
│   └── sprint-1/           # Sprint 1 documentation
└── README.md                 # This file
```

## 🔧 Development

### Backend Development
- **Directus:** Headless CMS voor data management
- **Airflow:** Orchestration voor data processing
- **PostgreSQL:** Primary database
- **Authentik:** SSO authentication

### Frontend Development
```bash
cd frontend
npm run dev          # Development server
npm run build        # Production build
npm run preview      # Preview production build
npm run lint         # ESLint
npm run type-check   # TypeScript checking
```

### Database Management
```bash
# Connect to PostgreSQL
docker exec -it gtin-postgres psql -U postgres -d gtin_finder

# View Directus data
docker exec -it gtin-postgres psql -U directus_user -d directus

# View Airflow metadata
docker exec -it gtin-postgres psql -U airflow_user -d airflow
```

### Airflow DAGs
DAGs worden automatisch geladen vanuit de `airflow/dags/` directory:
- `gtin_validator_dag.py` - Valideert GTIN codes
- `example_dag.py` - Test DAG voor setup verificatie

## 🧪 Testing

### Backend Tests
```bash
# Test database connection
docker exec gtin-postgres pg_isready -U postgres

# Test Directus API
curl http://localhost:8055/health

# Test Airflow
curl http://localhost:8080/health

# Test Authentik
curl http://localhost:9000
```

### Frontend Tests
```bash
cd frontend
npm run test          # Unit tests
npm run test:e2e      # End-to-end tests (when implemented)
```

## 📊 Monitoring

### Health Checks
- **Overall:** http://localhost/health
- **Directus:** http://localhost:8055/health
- **Airflow:** http://localhost:8080/health
- **Authentik:** http://auth.localhost/health

### Logs
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f directus
docker-compose logs -f airflow
docker-compose logs -f authentik
docker-compose logs -f postgresql
```

## 🔒 Security

### Authentication
- SSO via Authentik (OIDC)
- Role-based access control
- API token authentication

### Network Security
- All services in isolated Docker network
- Nginx reverse proxy with security headers
- HTTPS ready (SSL certificates nodig voor production)

### Data Security
- Encrypted database connections
- Environment variables voor sensitive data
- Regular security updates via Docker images

## 🚀 Deployment

### Production Deployment
1. **Environment Setup**
   - Configureer production environment variables
   - Zet SSL certificates op
   - Configureer backup strategy

2. **Database**
   - PostgreSQL met replication
   - Regular backups
   - Monitoring en alerting

3. **Application**
   - Docker Swarm of Kubernetes
   - Load balancing
   - Auto-scaling

4. **Monitoring**
   - Grafana dashboards
   - Prometheus metrics
   - Log aggregation

## 📚 Documentation

- **[Project Plan](docs/v1.0-project-plan.md)** - Complete technische specificaties
- **[Sprint Planning](docs/sprint-planning.md)** - Gedetailleerde sprint planning
- **[Sprint 1](docs/sprint-1/)** - Sprint 1 documentatie en user stories
- **[Methodology](docs/werkwijze-projectplanning.md)** - Gebruikte werkwijze

## 🤝 Contributing

1. Fork de repository
2. Maak een feature branch (`git checkout -b feature/amazing-feature`)
3. Commit je changes (`git commit -m 'Add amazing feature'`)
4. Push naar de branch (`git push origin feature/amazing-feature`)
5. Open een Pull Request

## 📄 License

Dit project is gelicenseerd onder de Apache License 2.0 - zie [LICENSE](LICENSE) file voor details.

## 🆘 Troubleshooting

### Common Issues

#### Port Conflicts
Als poorten al in gebruik zijn:
```bash
# Check welke poorten bezet zijn
lsof -i :3000,8055,8080,9000,5432

# Stop conflicterende services of verander poorten in docker-compose.yml
```

#### Database Connection Issues
```bash
# Check database status
docker-compose ps postgresql

# Restart database
docker-compose restart postgresql

# Check logs
docker-compose logs postgresql
```

#### Frontend Build Issues
```bash
# Clear node modules
cd frontend
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
npm run dev -- --force
```

#### Authentication Issues
```bash
# Check Authentik status
docker-compose logs authentik

# Reset Authentik (data loss!)
docker-compose down -v
docker-compose up -d authentik
```

### Getting Help

- Check de [documentation](docs/) voor gedetailleerde informatie
- Open een [issue](https://github.com/your-repo/gtin-finder/issues) voor bugs
- Contact het development team voor support

---

**GTINFinder** - Advanced GTIN Data Enrichment Platform  
Built with ❤️ using modern web technologies
