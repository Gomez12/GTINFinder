-- GTINFinder Database Initialization Script
-- PostgreSQL compatible version

-- Create databases (PostgreSQL doesn't support IF NOT EXISTS for CREATE DATABASE)
SELECT 'CREATE DATABASE directus'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'directus')\gexec

SELECT 'CREATE DATABASE airflow'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'airflow')\gexec

SELECT 'CREATE DATABASE authentik'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'authentik')\gexec

-- Create users
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'directus_user') THEN
      CREATE USER directus_user WITH PASSWORD 'directus_secure_password';
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'airflow_user') THEN
      CREATE USER airflow_user WITH PASSWORD 'airflow_secure_password';
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authentik_user') THEN
      CREATE USER authentik_user WITH PASSWORD 'authentik_secure_password';
   END IF;
END
$$;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE directus TO directus_user;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow_user;
GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik_user;

-- Grant schema permissions for all services
\c directus
GRANT ALL ON SCHEMA public TO directus_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO directus_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO directus_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO directus_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO directus_user;

\c airflow
GRANT ALL ON SCHEMA public TO airflow_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO airflow_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO airflow_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO airflow_user;

\c authentik
GRANT ALL ON SCHEMA public TO authentik_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authentik_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authentik_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authentik_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authentik_user;
