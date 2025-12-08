# GTINFinder - AI Agent Guidelines

This file contains guidelines and commands for AI agents working in this repository.

## 🚀 Quick Reference

### Essential Commands
```bash
# Frontend development
make frontend-dev          # Start React dev server
make frontend-build         # Build for production
make frontend-lint          # Run ESLint
make frontend-test          # Run tests

# Backend/Airflow
make up                    # Start all services
make logs airflow          # Show Airflow logs
make db-shell              # Connect to PostgreSQL
make health                # Check all service health

# Single test execution
make test-frontend         # Run frontend tests only
```

## 🏗️ Project Structure

```
gtin-finder/
├── frontend/                 # React TypeScript app
│   ├── src/
│   │   ├── components/    # Reusable UI components
│   │   ├── pages/        # Page components
│   │   ├── services/      # API clients
│   │   ├── types/         # TypeScript types
│   │   └── utils/         # Utility functions
│   ├── public/              # Static assets
│   ├── package.json         # Dependencies and scripts
│   ├── .eslintrc.json       # ESLint configuration
│   ├── tsconfig.json        # TypeScript configuration
│   └── vite.config.ts       # Vite build tool
├── airflow/                  # Airflow DAGs and config
│   ├── dags/               # DAG definitions
│   └── airflow.cfg          # Airflow configuration
├── database/                 # Database initialization
└── docs/                     # Documentation
```

## 📋 Frontend Development Guidelines

### Build Commands
```bash
# Install dependencies
make frontend-install
# or: cd frontend && npm install

# Start development server
make frontend-dev
# or: cd frontend && npm run dev

# Build for production
make frontend-build
# or: cd frontend && npm run build

# Run tests
make frontend-test
# or: cd frontend && npm test

# Lint code
make frontend-lint
# or: cd frontend && npm run lint

# Format code
cd frontend && npm run format  # if available
```

### Code Style Requirements

#### TypeScript Configuration
- **Strict mode enabled** in `tsconfig.app.json`
- **No implicit any** - Use explicit types
- **No unused variables/parameters**
- **ES2022 target** with DOM lib support

#### ESLint Rules
Based on `.eslintrc.json`:
```json
{
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "prettier"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-explicit-any": "warn"
  }
}
```

#### Import/Export Conventions
```typescript
// ✅ Correct imports
import React, { useState, useEffect } from 'react';
import { DirectusClient } from './services/directus';
import type { GTIN, Product } from './types';

// ✅ Named exports
export const GTINInput: React.FC<GTINInputProps> = ({ value, onChange }) => {
  // Component implementation
};

export type { GTIN, Product };
```

#### Component Structure
```typescript
// ✅ Functional components with TypeScript interfaces
interface ButtonProps {
  children: React.ReactNode;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}

export const Button: React.FC<ButtonProps> = ({ 
  children, 
  onClick, 
  variant = 'primary' 
}) => {
  return (
    <button 
      className={`btn btn-${variant}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

#### Error Handling
```typescript
// ✅ Proper error handling with types
interface APIResponse<T> {
  data?: T;
  error?: string;
  status: number;
}

const fetchGTIN = async (gtin: string): Promise<APIResponse<Product>> => {
  try {
    const response = await directus.items('products').readByQuery({
      filter: { gtin: { _eq: gtin } }
    });
    return { data: response.data, status: 200 };
  } catch (error) {
    return { 
      error: error instanceof Error ? error.message : 'Unknown error', 
      status: 500 
    };
  }
};
```

## 🔧 Backend Development Guidelines

### Airflow DAG Structure
```python
# ✅ Correct DAG structure with proper imports
from __future__ import annotations
from datetime import datetime
from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
}

with DAG(
    dag_id='gtin_validator_dag',
    default_args=default_args,
    schedule_interval=None,
    catchup=False,
    tags=['gtin', 'validation'],
) as dag:
    validate_gtin_task = PythonOperator(
        task_id='validate_gtin',
        python_callable=validate_gtin_function,
    )
```

### Database Operations
```bash
# ✅ Safe database operations
make db-shell  # Connect to PostgreSQL

# In database shell
\l                    # List databases
\c directus           # Connect to Directus database
\dt                   # List tables
SELECT * FROM gtins LIMIT 10;  # Query data
```

## 🧪 Testing Guidelines

### Frontend Testing
```bash
# Run all frontend tests
make frontend-test

# Run specific test file
cd frontend && npm test -- GTINInput.test.tsx

# Run tests with coverage
cd frontend && npm run test -- --coverage
```

### Test File Structure
```typescript
// ✅ Test file naming and structure
import { render, screen } from '@testing-library/react';
import { GTINInput } from '../components/GTINInput';

describe('GTINInput Component', () => {
  test('renders input field', () => {
    render(<GTINInput />);
    expect(screen.getByRole('textbox')).toBeInTheDocument();
  });

  test('validates GTIN format', () => {
    const onChange = jest.fn();
    render(<GTINInput onChange={onChange} />);
    
    const input = screen.getByRole('textbox');
    fireEvent.change(input, '123');
    
    expect(onChange).toHaveBeenCalledWith('123');
  });
});
```

## 📏 Code Quality Standards

### Before Committing
```bash
# 1. Run linting
make frontend-lint

# 2. Run tests
make frontend-test

# 3. Check types
cd frontend && npx tsc --noEmit

# 4. Format code
cd frontend && npm run format  # if prettier is configured
```

### Git Hooks (if configured)
```bash
# Pre-commit hooks typically run:
# - lint-staged
# - type-check
# - unit-tests
```

## 🚨 Common Issues & Solutions

### Frontend Build Issues
```bash
# Clear build cache
rm -rf frontend/node_modules frontend/dist
make frontend-install

# Check Node.js version
node --version  # Should be 18+
```

### Docker Issues
```bash
# Check container status
make status

# View specific service logs
make logs airflow
make logs directus

# Restart specific service
docker-compose restart airflow

# Complete reset
make reset
```

### Environment Variables
```bash
# Check current environment
cat .env

# Regenerate environment
make setup  # This recreates .env with new keys
```

## 🎯 Single Test Execution

### Running One Test
```bash
# Test specific component
cd frontend && npm test -- --testNamePattern="GTINInput"

# Test with watch mode
cd frontend && npm test -- --watch

# Test specific file
cd frontend && npm test GTINInput.test.tsx
```

### Debug Mode
```bash
# Start frontend with debug
cd frontend && npm run dev:debug

# Airflow debug mode
docker-compose exec airflow airflow dags list
docker-compose exec airflow airflow tasks list gtin_validator_dag
```

## 📝 Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/gtin-validation

# Make changes
# Edit files...

# Run tests
make frontend-test

# Commit changes
git add .
git commit -m "feat: add GTIN validation component"
```

### 2. Code Review Checklist
- [ ] TypeScript compiles without errors
- [ ] ESLint passes
- [ ] Tests pass
- [ ] Components follow established patterns
- [ ] Error handling implemented
- [ ] Types are properly defined

### 3. Integration Testing
```bash
# Start all services
make up

# Run integration tests
# (Add when implemented)

# Check service health
make health
```

## 🔐 Security Guidelines

### Environment Variables
- Never commit `.env` files
- Use `env.example` as template
- Generate secrets with `make setup`

### API Keys
- Store in environment variables, not code
- Use different keys for development/production
- Rotate keys regularly

### Database Security
- Use connection strings from environment
- Never hardcode credentials
- Validate all inputs

## 📚 Documentation Maintenance

### Keeping Documentation Up-to-Date

This repository contains several documentation files that must be maintained in sync with the actual implementation:

#### Core Documentation Files
- `docs/setup-guide.md` - Primary setup and configuration guide
- `docs/v1.0-project-plan.md` - Architecture and technical specifications  
- `docs/sprint-*/README.md` - Sprint progress and objectives
- `docs/sprint-*/technical-tasks.md` - Detailed implementation tasks
- `docs/sprint-*/test-guide.md` - Testing procedures and checklists
- `docs/sprint-*/user-stories.md` - Feature requirements and acceptance criteria

#### When to Update Documentation
Update documentation when:
- **New features are implemented** - Update relevant sprint docs
- **Configuration changes** - Update setup guide and AGENTS.md
- **Build processes change** - Update build commands in AGENTS.md
- **New services added** - Update architecture docs
- **Testing procedures evolve** - Update test guides
- **Security practices updated** - Update security guidelines

#### Documentation Update Process
1. **Make changes** to relevant documentation files
2. **Update version numbers** and dates
3. **Commit changes** with descriptive messages
4. **Verify consistency** across all documentation files

#### Version Control Strategy
- **Major changes**: Update version in project plan
- **Minor updates**: Update "Last Updated" date in affected files
- **Hotfixes**: Update specific sections without version change

---

**Agent Guidelines Version**: 1.0  
**Last Updated**: 2025-12-08  
**Repository**: GTINFinder