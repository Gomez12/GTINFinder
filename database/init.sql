-- GTINFinder Database Initialization Script
-- This script creates all necessary databases and users for the GTINFinder application

-- Create databases
CREATE DATABASE directus;
CREATE DATABASE airflow;
CREATE DATABASE authentik;

-- Create users with specific permissions
CREATE USER directus_user WITH PASSWORD 'directus_secure_password';
CREATE USER airflow_user WITH PASSWORD 'airflow_secure_password';
CREATE USER authentik_user WITH PASSWORD 'authentik_secure_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE directus TO directus_user;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow_user;
GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik_user;

-- Connect to directus database and create extensions
\c directus;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Connect to airflow database and create extensions
\c airflow;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Connect to authentik database and create extensions
\c authentik;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO directus_user;
GRANT ALL ON SCHEMA public TO airflow_user;
GRANT ALL ON SCHEMA public TO authentik_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO directus_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO airflow_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authentik_user;

-- Create initial GTIN table structure (for Directus to use)
\c directus;
CREATE TABLE IF NOT EXISTS gtins (
    id SERIAL PRIMARY KEY,
    gtin_code VARCHAR(14) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gtin_raw_data (
    id SERIAL PRIMARY KEY,
    gtin_id INTEGER REFERENCES gtins(id) ON DELETE CASCADE,
    source_name VARCHAR(100) NOT NULL,
    raw_data JSONB,
    quality_score DECIMAL(3,2) DEFAULT 0.00,
    retrieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gtin_golden_records (
    id SERIAL PRIMARY KEY,
    gtin_id INTEGER REFERENCES gtins(id) ON DELETE CASCADE,
    merged_data JSONB,
    confidence_score DECIMAL(3,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS data_sources (
    id SERIAL PRIMARY KEY,
    source_name VARCHAR(100) UNIQUE NOT NULL,
    api_endpoint TEXT,
    rate_limit INTEGER DEFAULT 100,
    status VARCHAR(50) DEFAULT 'active',
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS data_quality_scores (
    id SERIAL PRIMARY KEY,
    gtin_id INTEGER REFERENCES gtins(id) ON DELETE CASCADE,
    source_name VARCHAR(100) NOT NULL,
    completeness DECIMAL(3,2) DEFAULT 0.00,
    accuracy DECIMAL(3,2) DEFAULT 0.00,
    freshness DECIMAL(3,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_gtins_gtin_code ON gtins(gtin_code);
CREATE INDEX IF NOT EXISTS idx_gtins_status ON gtins(status);
CREATE INDEX IF NOT EXISTS idx_gtin_raw_data_gtin_id ON gtin_raw_data(gtin_id);
CREATE INDEX IF NOT EXISTS idx_gtin_raw_data_source ON gtin_raw_data(source_name);
CREATE INDEX IF NOT EXISTS idx_gtin_golden_records_gtin_id ON gtin_golden_records(gtin_id);
CREATE INDEX IF NOT EXISTS idx_data_quality_scores_gtin_id ON data_quality_scores(gtin_id);

-- Insert some initial data sources
INSERT INTO data_sources (source_name, api_endpoint, rate_limit, priority) VALUES
('open_food_facts', 'https://world.openfoodfacts.org/api/v2/product', 100, 1),
('go_upc', 'https://go-upc.com/api/v1/code', 50, 2),
('ean_search', 'https://api.ean-search.org/api', 100, 3),
('barcode_lookup', 'https://api.barcodelookup.com/v2/products', 50, 4)
ON CONFLICT (source_name) DO NOTHING;

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for gtins table
CREATE TRIGGER update_gtins_updated_at 
    BEFORE UPDATE ON gtins 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions on all tables to directus_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO directus_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO directus_user;

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'GTINFinder database initialization completed successfully!';
    RAISE NOTICE 'Databases created: directus, airflow, authentik';
    RAISE NOTICE 'Users created: directus_user, airflow_user, authentik_user';
    RAISE NOTICE 'Tables created in directus database';
END $$;
