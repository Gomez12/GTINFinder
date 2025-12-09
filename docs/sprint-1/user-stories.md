# Sprint 1 User Stories - Foundation

**Sprint:** 1 (Week 1-2)  
**Goal:** Working Infrastructure  
**Total Stories:** 12  
**Total Story Points:** 40  

---

## 🐳 Story 1: Docker Compose Setup

**Als** developer  
**wil ik** een Docker Compose setup met alle core services  
**zodat** ik de volledige GTINFinder infrastructuur lokaal kan draaien

### Acceptance Criteria
- [ ] `docker-compose up` start alle services zonder errors
- [ ] Alle services zijn bereikbaar op hun standaard poorten
- [ ] Environment variables zijn correct geconfigureerd
- [ ] Volumes zijn persistent voor data opslag
- [ ] Services kunnen onafhankelijk van elkaar herstart worden

### Technical Requirements
- [ ] Docker Compose file met alle services (PostgreSQL, Directus, Airflow, Authentik, Redis, Nginx)
- [ ] Environment file met alle benodigde variabelen
- [ ] Network configuratie voor service communicatie
- [ ] Volume mounts voor persistent data
- [ ] Health checks voor alle services

### Tasks
#### Backend/Infra
- [ ] Maak docker-compose.yml met alle services
- [ ] Configureer PostgreSQL met persistent volume
- [ ] Configureer Directus service
- [ ] Configureer Airflow met PostgreSQL backend
- [ ] Configureer Authentik met PostgreSQL backend
- [ ] Configureer Redis voor caching
- [ ] Configureer Nginx als reverse proxy
- [ ] Maak .env template met alle environment variables

### Definition of Done
- [ ] Code is geschreven en gecommit
- [ ] `docker-compose up` draait zonder errors
- [ ] Alle services zijn healthy na startup
- [ ] Documentation is bijgewerkt met setup instructies

### Estimation
**Story Points:** 8  
**Complexity:** Hoog  
**Risk:** Medium

---

## 🗄️ Story 2: PostgreSQL Database Setup

**Als** developer  
**wil ik** een PostgreSQL database met correct schema  
**zodat** Directus en Airflow data kunnen opslaan

### Acceptance Criteria
- [ ] PostgreSQL database draait en is bereikbaar
- [ ] Directus database schema is aangemaakt
- [ ] Airflow metadata database is geconfigureerd
- [ ] Authentik database is geconfigureerd
- [ ] Database users hebben correcte permissions
- [ ] Connection pooling is geconfigureerd

### Technical Requirements
- [ ] PostgreSQL 15+ container
- [ ] Separate databases voor elke service
- [ ] Database users met beperkte rechten
- [ ] Connection limits en pooling configuratie
- [ ] Backup en recovery scripts

### Tasks
#### Backend/Infra
- [ ] Configureer PostgreSQL container in docker-compose
- [ ] Maak databases: directus, airflow, authentik
- [ ] Maak users: directus_user, airflow_user, authentik_user
- [ ] Configureer connection pooling
- [ ] Maak init scripts voor database setup
- [ ] Test database connectivity vanaf elke service

### Definition of Done
- [ ] Alle databases zijn aangemaakt en toegankelijk
- [ ] Users hebben correcte permissions
- [ ] Connection tests slagen vanaf alle services
- [ ] Database schema's zijn gevalideerd

### Estimation
**Story Points:** 5  
**Complexity:** Medium  
**Risk:** Laag

---

## 🚀 Story 3: Directus Installation & Configuration

**Als** developer  
**wil ik** Directus geïnstalleerd en geconfigureerd  
**zodat** ik een headless CMS heb voor data management

### Acceptance Criteria
- [ ] Directus admin interface is bereikbaar op http://localhost:8055
- [ ] Admin user kan aanmaken en inloggen
- [ ] Collections kunnen aanmaken via UI
- [ ] API endpoints zijn bereikbaar
- [ ] Authentication is geconfigureerd
- [ ] File uploads werken correct

### Technical Requirements
- [ ] Directus 10+ container
- [ ] PostgreSQL database connectie
- [ ] Admin account setup
- [ ] API token authenticatie
- [ ] File storage configuratie
- [ ] CORS settings voor frontend

### Tasks
#### Backend/Infra
- [ ] Configureer Directus container
- [ ] Stel database connectie in
- [ ] Maak admin account aan
- [ ] Configureer API tokens
- [ ] Stel file storage in
- [ ] Configureer CORS voor frontend development
- [ ] Test admin interface functionaliteit
- [ ] Test API endpoints

### Definition of Done
- [ ] Directus UI is volledig functioneel
- [ ] API endpoints returnen correcte responses
- [ ] File uploads werken
- [ ] Admin user kan collections beheren

### Estimation
**Story Points:** 6  
**Complexity:** Medium  
**Risk:** Laag

---

## 💨 Story 4: Airflow Setup with Basic DAGs

**Als** developer  
**wil ik** Airflow geconfigureerd met basis DAGs  
**zodat** ik data processing pipelines kan orkestreren

### Acceptance Criteria
- [ ] Airflow UI is bereikbaar op http://localhost:8080
- [ ] Admin user kan inloggen
- [ ] Basis DAG template is beschikbaar
- [ ] DAGs kunnen worden geactiveerd
- [ ] DAG runs zijn zichtbaar in UI
- [ ] Logging werkt correct

### Technical Requirements
- [ ] Airflow 2.7+ container
- [ ] PostgreSQL metadata database
- [ ] Redis als message broker
- [ ] DAGs folder met volume mount
- [ ] Admin user setup
- [ ] Basic DAG template

### Tasks
#### Backend/Infra
- [ ] Configureer Airflow container
- [ ] Stel PostgreSQL metadata database in
- [ ] Configureer Redis als broker
- [ ] Maak admin account aan
- [ ] Maak basis DAG template
- [ ] Configureer DAGs folder
- [ ] Test DAG activation en execution
- [ ] Test logging functionaliteit

### Definition of Done
- [ ] Airflow UI is volledig functioneel
- [ ] Basis DAG kan succesvol draaien
- [ ] Logs zijn zichtbaar in UI
- [ ] Admin user kan DAGs beheren

### Estimation
**Story Points:** 6  
**Complexity:** Medium  
**Risk:** Medium

---

## 🔐 Story 5: Authentik SSO Configuration

**Als** developer  
**wil ik** Authentik geconfigureerd als SSO provider  
**zodat** gebruikers kunnen authenticeren via OIDC

### Acceptance Criteria
- [ ] Authentik admin interface is bereikbaar
- [ ] Admin user kan aanmaken en inloggen
- [ ] OIDC provider is geconfigureerd
- [ ] Application kan aanmaken voor GTINFinder
- [ ] Client credentials zijn gegenereerd
- [ ] OIDC discovery endpoint werkt

### Technical Requirements
- [ ] Authentik container
- [ ] PostgreSQL database
- [ ] Admin account setup
- [ ] OIDC provider configuratie
- [ ] Application setup voor GTINFinder
- [ ] Client ID en secret generatie

### Tasks
#### Backend/Infra
- [ ] Configureer Authentik container
- [ ] Stel database connectie in
- [ ] Maak admin account aan
- [ ] Configureer OIDC provider
- [ ] Maak GTINFinder application
- [ ] Genereer client credentials
- [ ] Test OIDC discovery endpoint
- [ ] Documenteer OIDC configuratie

### Definition of Done
- [ ] Authentik UI is functioneel
- [ ] OIDC provider is geconfigureerd
- [ ] Application credentials zijn beschikbaar
- [ ] Discovery endpoint is bereikbaar

### Estimation
**Story Points:** 5  
**Complexity:** Medium  
**Risk:** Medium

---

## ⚛️ Story 6: React + TypeScript Project Setup

**Als** developer  
**wil ik** een React app met TypeScript setup  
**zodat** ik een moderne frontend kan bouwen

### Acceptance Criteria
- [ ] React 18+ project is aangemaakt
- [ ] TypeScript is geconfigureerd
- [ ] Vite build tool is geconfigureerd
- [ ] Tailwind CSS is geïnstalleerd
- [ ] Development server draait op http://localhost:3000
- [ ] Hot module replacement werkt
- [ ] TypeScript types zijn correct geconfigureerd

### Technical Requirements
- [ ] React 18+ met TypeScript
- [ ] Vite als build tool
- [ ] Tailwind CSS voor styling
- [ ] ESLint en Prettier configuratie
- [ ] Development environment setup
- [ ] Basic project structuur

### Tasks
#### Frontend
- [ ] Maak React project met Vite en TypeScript
- [ ] Installeer en configureer Tailwind CSS
- [ ] Configureer ESLint en Prettier
- [ ] Maak basis project structuur
- [ ] Configureer development server
- [ ] Test hot module replacement
- [ ] Maak basic component voor testing
- [ ] Configureer build process

### Definition of Done
- [ ] React app draait zonder TypeScript errors
- [ ] Development server werkt correct
- [ ] Tailwind CSS styling werkt
- [ ] Build process genereert correct output

### Estimation
**Story Points:** 4  
**Complexity:** Laag  
**Risk:** Laag

---

## 🔗 Story 7: OIDC Client Integration

**Als** user  
**wil ik** in kunnen loggen via Authentik SSO  
**zodat** ik beveiligde toegang heb tot de applicatie

### Acceptance Criteria
- [ ] Login button is zichtbaar op homepage
- [ ] Klikken op login redirect naar Authentik
- [ ] Authentik login flow werkt correct
- [ ] Na succesvolle login redirect terug naar app
- [ ] User info is beschikbaar in frontend
- [ ] Logout functionaliteit werkt
- [ ] Token refresh werkt automatisch

### Technical Requirements
- [ ] OIDC client library (react-oidc-context)
- [ ] Authentik OIDC configuration
- [ ] Protected routes implementatie
- [ ] Token storage en refresh
- [ ] User session management
- [ ] Error handling voor auth failures

### Tasks
#### Frontend
- [x] Installeer OIDC client library
- [x] Configureer OIDC settings
- [x] Implementeer login component
- [x] Implementeer protected routes
- [x] Implementeer logout functionaliteit
- [x] Test complete auth flow
- [x] Implementeer error handling
- [x] Test token refresh mechanisme

#### Backend/Infra (NIEUW)
- [x] **Automatiseer Authentik OIDC Provider setup via setup.sh**
- [x] **Automatiseer Authentik Application setup via setup.sh**
- [x] **Configureer OIDC endpoints voor frontend integratie**
- [x] **Genereer Client ID en Secret automatisch**

### Definition of Done
- [x] Login flow werkt end-to-end
- [x] User is correct geauthenticeerd
- [x] Protected routes zijn beveiligd
- [x] Logout werkt correct
- [x] Token refresh werkt automatisch
- [x] **OIDC Provider en Application automatisch geconfigureerd**
- [x] **make setup bevat volledige SSO automatisering**

### Estimation
**Story Points:** 5  
**Complexity:** Medium  
**Risk:** Medium

---

## 📝 Story 8: Basic GTIN Input Form

**Als** user  
**wil ik** een simpele GTIN input interface  
**zodat** ik barcode codes kan invoeren

### Acceptance Criteria
- [ ] Input form is zichtbaar op homepage
- [ ] GTIN input field accepteert 8, 12, 13, 14 digit codes
- [ ] Real-time validatie van GTIN formaat
- [ ] Submit button is disabled bij invalid input
- [ ] Loading state tijdens verwerking
- [ ] Success/error feedback is zichtbaar
- [ ] Form reset na succesvolle submission

### Technical Requirements
- [ ] React form component
- [ ] GTIN validatie logic
- [ ] State management voor form data
- [ ] API integration voor submission
- [ ] Loading en error states
- [ ] Form reset functionaliteit

### Tasks
#### Frontend
- [ ] Maak GTIN input component
- [ ] Implementeer GTIN validatie logic
- [ ] Maak form state management
- [ ] Implementeer API call voor submission
- [ ] Voeg loading states toe
- [ ] Implementeer error handling
- [ ] Test form validatie
- [ ] Test submission flow

### Definition of Done
- [ ] Form valideert GTIN codes correct
- [ ] Submission werkt zonder errors
- [ ] Loading states zijn zichtbaar
- [ ] Error feedback is duidelijk
- [ ] Form reset werkt correct

### Estimation
**Story Points:** 3  
**Complexity:** Laag  
**Risk:** Laag

---

## 🔌 Story 9: Directus API Integration

**Als** developer  
**wil ik** GTIN data kunnen opslaan via Directus API  
**zodat** gebruikersinvoer persistent wordt opgeslagen

### Acceptance Criteria
- [ ] GTIN kan opslaan in Directus via API
- [ ] API response bevat opgeslagen data
- [ ] Error handling voor API failures
- [ ] Authentication met Directus API werkt
- [ ] Data validatie op server-side
- [ ] API rate limiting is gerespecteerd

### Technical Requirements
- [ ] Directus SDK of HTTP client
- [ ] API authentication (token-based)
- [ ] GTIN collection in Directus
- [ ] Error handling en retry logic
- [ ] Data validation
- [ ] API response handling

### Tasks
#### Backend/Frontend
- [ ] Installeer Directus SDK of configureer HTTP client
- [ ] Maak GTIN collection in Directus
- [ ] Implementeer API authentication
- [ ] Maak GTIN creation endpoint
- [ ] Implementeer error handling
- [ ] Test API integration
- [ ] Test data validation
- [ ] Test error scenarios

### Definition of Done
- [ ] GTIN data wordt correct opgeslagen
- [ ] API responses zijn correct
- [ ] Error handling werkt
- [ ] Authentication is beveiligd
- [ ] Data validation werkt

### Estimation
**Story Points:** 4  
**Complexity:** Medium  
**Risk:** Laag

---

## 🎨 Story 10: Basic UI Styling

**Als** user  
**wil ik** een strakke en gebruiksvriendelijke interface  
**zodat** de applicatie professioneel oogt en makkelijk te gebruiken is

### Acceptance Criteria
- [ ] Responsive design werkt op desktop en tablet
- [ ] Consistente kleurenschema en typografie
- [ ] Loading states hebben spinners of progress indicators
- [ ] Error states zijn duidelijk zichtbaar
- [ ] Success states hebben positieve feedback
- [ ] Formulier elementen zijn toegankelijk
- [ ] Navigatie is intuïtief

### Technical Requirements
- [ ] Tailwind CSS configuratie
- [ ] Design system met tokens
- [ ] Responsive breakpoints
- [ ] Component library basis
- [ ] Accessibility (WCAG) richtlijnen
- [ ] Loading en error componenten

### Tasks
#### Frontend
- [ ] Definieer design tokens (kleuren, typografie)
- [ ] Maak responsive layout componenten
- [ ] Implementeer loading states
- [ ] Implementeer error states
- [ ] Maak form componenten met styling
- [ ] Test responsive design
- [ ] Test accessibility
- [ ] Optimaliseer performance

### Definition of Done
- [ ] UI is responsive op alle devices
- [ ] Design is consistent
- [ ] Loading en error states zijn duidelijk
- [ ] Accessibility requirements zijn voldaan
- [ ] Performance is geoptimaliseerd

### Estimation
**Story Points:** 3  
**Complexity:** Laag  
**Risk:** Laag

---

## 🧪 Story 11: Basic Error Handling

**Als** user  
**wil ik** duidelijke foutmeldingen bij problemen  
**zodat** ik weet wat er mis is en hoe ik het kan oplossen

### Acceptance Criteria
- [ ] Network errors tonen duidelijke meldingen
- [ ] Validation errors zijn specifiek per veld
- [ ] API errors tonen user-friendly berichten
- [ ] Timeout errors hebben passende meldingen
- [ ] Authentication errors zijn duidelijk
- [ ] Error logging werkt voor debugging
- [ ] Retry optie is beschikbaar waar mogelijk

### Technical Requirements
- [ ] Global error handling
- [ ] Error boundary componenten
- [ ] User-friendly error messages
- [ ] Error logging mechanisme
- [ ] Retry logic voor transient failures
- [ ] Toast/notification system

### Tasks
#### Frontend
- [ ] Implementeer global error handler
- [ ] Maak error boundary componenten
- [ ] Ontwerp error message system
- [ ] Implementeer error logging
- [ ] Voeg retry logic toe
- [ ] Test alle error scenarios
- [ ] Test error logging
- [ ] Test retry mechanisme

### Definition of Done
- [ ] Alle errors worden afgevangen
- [ ] Error messages zijn user-friendly
- [ ] Logging werkt voor debugging
- [ ] Retry mechanisme werkt waar nodig
- [ ] Geen uncaught exceptions

### Estimation
**Story Points:** 3  
**Complexity:** Medium  
**Risk:** Laag

---

## 📚 Story 12: Documentation & Setup Guide

**Als** developer  
**wil ik** complete documentatie voor setup en gebruik  
**zodat** nieuwe team members snel aan de slag kunnen

### Acceptance Criteria
- [ ] README.md met setup instructies
- [ ] Environment variables documentatie
- [ ] API documentatie voor endpoints
- [ ] Troubleshooting guide voor common issues
- [ ] Development workflow documentatie
- [ ] Architecture overview diagrammen
- [ ] Contributing guidelines

### Technical Requirements
- [ ] Markdown documentatie
- [ ] Setup scripts indien nodig
- [ ] API examples
- [ ] Diagrammen voor architectuur
- [ ] Code examples
- [ ] Step-by-step guides

### Tasks
#### Documentation
- [ ] Schrijf README.md met setup instructies
- [ ] Documenteer environment variables
- [ ] Maak API documentatie
- [ ] Schrijf troubleshooting guide
- [ ] Documenteer development workflow
- [ ] Maak architectuur diagrammen
- [ ] Schrijf contributing guidelines
- [ ] Test setup instructies

### Definition of Done
- [ ] Documentatie is compleet en actueel
- [ ] Setup instructies werken
- [ ] API documentatie is correct
- [ ] Troubleshooting guide is nuttig
- [ ] Nieuwe developers kunnen setup volgen

### Estimation
**Story Points:** 2  
**Complexity:** Laag  
**Risk:** Laag

---

## 📊 Sprint Overview

### Story Distribution
- **Backend/Infra:** 6 stories (24 points)
- **Frontend:** 6 stories (16 points)
- **Total:** 12 stories (40 points)

### Dependencies
- Story 1 (Docker Compose) → Alle andere stories
- Story 2 (PostgreSQL) → Stories 3, 4, 5
- Story 5 (Authentik) → Story 7 (OIDC Integration)
- Story 6 (React Setup) → Stories 7, 8, 9, 10, 11

### Risk Matrix
| Story | Risk | Impact | Mitigation |
|-------|------|--------|------------|
| Story 1 | Medium | High | Test early, have fallback manual setup |
| Story 4 | Medium | Medium | Use proven Airflow configurations |
| Story 5 | Medium | Medium | Follow Authentik documentation closely |

### Acceptance Criteria
- [ ] Alle services draaien via `docker-compose up`
- [ ] Directus admin interface toegankelijk
- [ ] Airflow UI toegankelijk met basis DAGs
- [ ] React app laadt en SSO login werkt
- [ ] Basis GTIN input form functional

---

**Sprint 1 is ready for development!** 🚀

**Next Steps:**
1. Prioriteer stories binnen de sprint
2. Wijs stories toe aan team members
3. Begin met Story 1 (Docker Compose Setup)
4. Parallel werk aan frontend en backend stories waar mogelijk

---
**Sprint 1 van 4 - Foundation**
