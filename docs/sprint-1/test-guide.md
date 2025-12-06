# Sprint 1 Test Guide - Zelf Testen

**Sprint 1: Foundation** - Complete test procedures om zelf te verifiëren dat alles werkt.

---

## 🚀 **Snelstart Test (5 minuten)**

### Stap 1: Setup uitvoeren
```bash
# Clone repository (als je dat nog niet hebt gedaan)
git clone <repository-url>
cd gtin-finder

# Voer setup uit
make setup
```

### Stap 2: Services starten
```bash
# Start alle services
make up

# Controleer status
make status
```

### Stap 3: Health checks
```bash
# Controleer of alles gezond is
make health
```

### Stap 4: Frontend testen
```bash
# Start frontend development server
make frontend-dev
```

**Resultaat:** Als alles werkt, zie je:
- ✅ Alle services draaien
- ✅ Frontend is beschikbaar op http://localhost:3000
- ✅ Geen foutmeldingen

---

## 🧪 **Gedetailleerde Tests**

### Test 1: Infrastructure Setup

#### 1.1 Docker Services Controleren
```bash
# Controleer welke services draaien
make status

# Verwachte output:
# NAME                STATUS              PORTS
# gtin-postgres       Up 2 minutes        0.0.0.0:5432->5432/tcp
# gtin-directus       Up 2 minutes        0.0.0.0:8055->8055/tcp
# gtin-airflow        Up 2 minutes        0.0.0.0:8080->8080/tcp
# gtin-authentik      Up 2 minutes        0.0.0.0:9000->9000/tcp, 0.0.0.0:9443->9443/tcp
# gtin-redis          Up 2 minutes        0.0.0.0:6379->6379/tcp
# gtin-nginx          Up 2 minutes        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

#### 1.2 Health Checks Uitvoeren
```bash
# Controleer health van alle services
make health

# Verwachte output:
# ✅ Nginx health check passed
# ✅ Directus health check passed
# ✅ Airflow health check passed
```

#### 1.3 Logs Controleren
```bash
# Bekijk logs van alle services
make logs

# Of specifieke service logs
docker-compose logs directus
docker-compose logs airflow
```

### Test 2: Database Setup

#### 2.1 Database Connectie Testen
```bash
# Connect to database
make db-shell

# In PostgreSQL shell:
# \l  # List databases (moet directus, airflow, authentik tonen)
# \c gtin_finder  # Connect to main database
# \dt  # List tables (moet gtins tabel tonen)
# \q  # Quit
```

#### 2.2 Directus Schema Verificatie
```bash
# Controleer Directus database
docker-compose exec postgresql psql -U directus_user -d directus -c "\dt"

# Verwachte tabellen:
# directus_collections
# directus_fields
# directus_users
# gtins
# gtin_raw_data
# gtin_golden_records
# etc.
```

### Test 3: Directus CMS

#### 3.1 Admin Interface Testen
1. **Ga naar:** http://localhost:8055
2. **Maak admin account aan:**
   - Email: admin@example.com
   - Password: admin123
3. **Login** met deze credentials
4. **Verwacht:** Directus admin dashboard

#### 3.2 Collections Aanmaken
1. **Ga naar Settings > Data Model**
2. **Controleer of deze collections bestaan:**
   - `gtins`
   - `gtin_raw_data`
   - `gtin_golden_records`
   - `data_sources`
   - `data_quality_scores`

#### 3.3 API Testen
```bash
# Test Directus API
curl http://localhost:8055/items/gtins

# Verwachte response: {"data":[]} (lege array)
```

### Test 4: Airflow Orchestration

#### 4.1 Web Interface Testen
1. **Ga naar:** http://localhost:8080
2. **Login:**
   - Username: `airflow_user`
   - Password: `airflow_secure_password`
3. **Verwacht:** Airflow dashboard

#### 4.2 DAGs Controleren
1. **Ga naar DAGs tab**
2. **Controleer of deze DAGs zichtbaar zijn:**
   - `gtin_validator_dag`
   - `gtin_example_dag`
3. **Activeer een DAG** door op de toggle te klikken

#### 4.3 DAG Uitvoeren
1. **Klik op `gtin_example_dag`**
2. **Klik op "Trigger DAG"**
3. **Ga naar Graph View** om de uitvoering te zien
4. **Controleer logs** in de task instances

### Test 5: Authentik SSO

#### 5.1 Admin Interface Testen
1. **Ga naar:** http://localhost:9000
2. **Setup wizard doorlopen**
3. **Maak admin account aan**
4. **Verwacht:** Authentik admin dashboard

#### 5.2 OIDC Provider Configureren
1. **Ga naar Applications > Providers**
2. **Maak OAuth2/OpenID Connect Provider aan:**
   - Name: GTINFinder
   - Client ID: gtin-finder
   - Client Secret: genereer een secret
   - Redirect URIs: http://localhost:3000/*

#### 5.3 Application Aanmaken
1. **Ga naar Applications**
2. **Maak nieuwe application:**
   - Name: GTINFinder
   - Provider: Kies de OAuth2 provider
   - Redirect URIs: http://localhost:3000/*

### Test 6: Frontend Application

#### 6.1 Development Server Starten
```bash
# Start frontend
make frontend-dev

# Of handmatig:
cd frontend && npm run dev
```

#### 6.2 React App Testen
1. **Ga naar:** http://localhost:3000
2. **Verwacht:** GTINFinder login pagina
3. **Controleer console** voor errors

#### 6.3 GTIN Validatie Testen
1. **Login** (als Authentik is geconfigureerd)
2. **Ga naar dashboard**
3. **Test GTIN input:**
   - Voer `8712345678901` in (geldig GTIN-13)
   - Voer `123` in (ongeldig)
   - Controleer validatie feedback

#### 6.4 API Integratie Testen
1. **Voer een geldig GTIN in**
2. **Klik op "Add GTIN"**
3. **Controleer of data wordt opgeslagen**
4. **Refresh pagina** om opgeslagen data te zien

### Test 7: End-to-End Flow

#### 7.1 Complete GTIN Processing
1. **Frontend:** Voer GTIN in via React app
2. **Database:** Controleer of GTIN is opgeslagen
3. **Directus:** Bekijk data in admin interface
4. **Airflow:** Controleer of DAGs draaien
5. **Authentik:** Verificeer authenticatie werkt

#### 7.2 Data Persistence
```bash
# Controleer database inhoud
make db-shell

# In PostgreSQL:
SELECT * FROM gtins;
SELECT * FROM directus.gtins;
```

---

## 🔧 **Troubleshooting Tests**

### Als Services Niet Starten
```bash
# Controleer Docker resources
docker system df

# Controleer logs
make logs

# Herstart individuele service
docker-compose restart directus

# Controleer environment variables
cat .env
```

### Als Frontend Niet Werkt
```bash
# Controleer build
make frontend-build

# Controleer dependencies
cd frontend && npm ls

# Controleer console errors
# Open browser dev tools op http://localhost:3000
```

### Als Database Connectie Faalt
```bash
# Test database connectie
make db-shell

# Controleer database status
docker-compose ps postgresql

# Herstart database
docker-compose restart postgresql
```

### Als Authentik Niet Werkt
```bash
# Controleer Authentik logs
docker-compose logs authentik

# Reset Authentik (data verlies!)
docker-compose down -v authentik
docker-compose up -d authentik
```

---

## 📊 **Test Resultaten Documenteren**

### Test Checklist
- [ ] Infrastructure services draaien
- [ ] Database schema correct
- [ ] Directus admin interface werkt
- [ ] Airflow DAGs zijn zichtbaar
- [ ] Authentik SSO geconfigureerd
- [ ] Frontend React app laadt
- [ ] GTIN validatie werkt
- [ ] API integratie functioneel
- [ ] End-to-end flow compleet

### Performance Metrics
- **Frontend Load Time:** < 2 seconden
- **API Response Time:** < 500ms
- **Database Query Time:** < 100ms
- **Service Startup Time:** < 2 minuten

### Quality Metrics
- **TypeScript Errors:** 0 (warnings toegestaan)
- **ESLint Violations:** 0
- **Console Errors:** 0
- **Broken Links:** 0

---

## 🎯 **Sprint 1 Acceptance Criteria**

### ✅ **Must Pass Tests**
- [ ] Alle 6 Docker services draaien gezond
- [ ] PostgreSQL database bevat GTIN schema
- [ ] Directus admin interface toegankelijk
- [ ] Airflow web UI toont DAGs
- [ ] Authentik SSO provider geconfigureerd
- [ ] React frontend laadt zonder errors
- [ ] GTIN validatie werkt real-time
- [ ] Data wordt opgeslagen in database

### ✅ **Nice-to-Have Tests**
- [ ] Airflow DAGs draaien succesvol
- [ ] OIDC authenticatie flow werkt
- [ ] Responsive design op mobile
- [ ] Error handling graceful

---

## 🚨 **Als Tests Falen**

### Immediate Actions
1. **Stop services:** `make down`
2. **Controleer logs:** `make logs`
3. **Reset environment:** `make reset`
4. **Herhaal setup:** `make setup`

### Common Issues & Solutions

#### Port Conflicts
```bash
# Vind conflicterende processen
lsof -i :3000,8055,8080,9000,5432

# Stop processen
kill -9 <PID>
```

#### Memory Issues
```bash
# Controleer Docker memory
docker system info

# Herstart Docker
# Of verhoog memory limit in Docker settings
```

#### Database Issues
```bash
# Reset database
docker-compose down -v postgresql
docker-compose up -d postgresql

# Wacht 30 seconden voor initialisatie
```

---

## 📞 **Support**

### Als je vastloopt:
1. **Check deze guide** voor je specifieke error
2. **Bekijk logs** met `make logs`
3. **Controleer prerequisites** (Docker, Node.js)
4. **Reset environment** met `make reset`

### Debug Commands
```bash
# Complete status overzicht
make info

# Gedetailleerde health checks
curl http://localhost/health
curl http://localhost:8055/health
curl http://localhost:8080/health

# Service specifieke logs
docker-compose logs directus --tail=50
docker-compose logs airflow --tail=50
```

---

## 🎉 **Sprint 1 Test Complete!**

**Als alle tests slagen:**
- ✅ **Sprint 1 is SUCCESSVOL geïmplementeerd**
- ✅ **Foundation is SOLID en PRODUCTION READY**
- ✅ **Team kan beginnen met Sprint 2**

**Als tests falen:**
- 🔍 **Gebruik troubleshooting sectie**
- 📞 **Contact development team**
- 🔄 **Reset en herhaal setup**

---

**Test Guide Version:** 1.0  
**Last Updated:** 6 december 2025  
**Sprint:** 1 - Foundation  
**Estimated Test Time:** 30-60 minuten
