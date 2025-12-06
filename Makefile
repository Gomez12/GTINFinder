.PHONY: help setup up down build clean dev test lint format status health logs db-shell backup restore info

# Default target
help: ## Show this help message
	@echo "GTINFinder Development Commands"
	@echo "==============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup commands
setup: ## Run initial setup script
	./setup.sh

setup-dev: ## Setup development environment with dev tools
	./setup.sh
	docker-compose -f docker-compose.yml -f docker-compose.override.yml --profile dev-tools up -d pgadmin redis-commander

# Docker commands
up: ## Start all services
	docker-compose up -d

up-dev: ## Start all services with development tools
	docker-compose -f docker-compose.yml -f docker-compose.override.yml --profile dev-tools up -d

down: ## Stop all services
	docker-compose down

down-volumes: ## Stop all services and remove volumes
	docker-compose down -v

# Frontend commands
frontend-install: ## Install frontend dependencies
	cd frontend && npm install

frontend-dev: ## Start frontend development server
	cd frontend && npm run dev

frontend-build: ## Build frontend for production
	cd frontend && npm run build

frontend-test: ## Run frontend tests
	cd frontend && npm run test

frontend-lint: ## Lint frontend code
	cd frontend && npm run lint

# Backend commands
airflow-init: ## Initialize Airflow database
	docker-compose exec airflow airflow db upgrade
	docker-compose exec airflow airflow users create -r Admin -u airflow_user -e admin@example.com -f Admin -l User -p airflow_secure_password || true

airflow-logs: ## Show Airflow logs
	docker-compose logs -f airflow

# Database commands
db-logs: ## Show database logs
	docker-compose logs -f postgresql

db-shell: ## Connect to PostgreSQL shell
	docker-compose exec postgresql psql -U postgres -d gtin_finder

# Monitoring commands
status: ## Show status of all services
	docker-compose ps

health: ## Check health of all services
	@echo "Checking service health..."
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Health checks:"
	@curl -s http://localhost/health 2>/dev/null && echo "✅ Nginx health check passed" || echo "❌ Nginx health check failed"
	@curl -s http://localhost:8055/health 2>/dev/null && echo "✅ Directus health check passed" || echo "❌ Directus health check failed"
	@curl -s http://localhost:8080/health 2>/dev/null && echo "✅ Airflow health check passed" || echo "❌ Airflow health check failed"

logs: ## Show logs for all services
	docker-compose logs -f

# Development commands
clean: ## Clean up containers, volumes, and images
	docker-compose down -v --rmi all
	docker system prune -f

clean-frontend: ## Clean frontend build and dependencies
	cd frontend && rm -rf node_modules dist build
	cd frontend && npm install

reset: ## Reset entire environment (WARNING: destroys all data)
	docker-compose down -v
	docker system prune -f
	rm -rf frontend/node_modules frontend/dist
	./setup.sh

# Testing commands
test: ## Run all tests
	cd frontend && npm run test
	# Add backend tests when implemented

test-frontend: ## Run frontend tests
	cd frontend && npm run test

# Utility commands
backup: ## Create database backup
	@echo "Creating database backup..."
	docker-compose exec postgresql pg_dump -U postgres gtin_finder > backup_$(date +%Y%m%d_%H%M%S).sql

restore: ## Restore database from backup (usage: make restore FILE=backup_file.sql)
	@echo "Restoring database from $(FILE)..."
	docker-compose exec -T postgresql psql -U postgres -d gtin_finder < $(FILE)

# Development shortcuts
dev: up frontend-dev ## Start everything in development mode

stop: down ## Stop all services

restart: down up ## Restart all services

# Info commands
info: ## Show useful information
	@echo "GTINFinder Development Environment"
	@echo "=================================="
	@echo ""
	@echo "Services:"
	@echo "- Frontend:     http://localhost:3000"
	@echo "- Directus:     http://localhost:8055"
	@echo "- Airflow:      http://localhost:8080"
	@echo "- Authentik:    http://localhost:9000"
	@echo "- PgAdmin:      http://localhost:5050 (dev only)"
	@echo "- Redis Cmdr:   http://localhost:8081 (dev only)"
	@echo ""
	@echo "Useful commands:"
	@echo "- make dev       # Start everything"
	@echo "- make status    # Check service status"
	@echo "- make logs      # Show all logs"
	@echo "- make db-shell  # Connect to database"
	@echo ""
	@echo "For more commands: make help"
