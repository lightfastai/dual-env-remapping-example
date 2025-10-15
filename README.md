# Dual Environment Remapping Example

This example demonstrates how `dual` manages environment variables across multiple git worktrees, providing complete isolation between different development contexts.

## What This Example Demonstrates

- **Automatic Environment Remapping**: Each worktree gets its own isolated environment variables
- **Service-Specific Overrides**: Set different env vars for each service within a context
- **Environment Cascading**: Services load vars from both base and service-specific files
- **Port Isolation**: Each worktree gets unique ports alongside unique environments
- **Built-in Support**: No custom hooks needed - dual handles remapping automatically

## How Environment Remapping Works

### File Structure

When you create a worktree and set environment variables, dual creates this structure:

```
worktrees/dev/
├── .dual/
│   └── .local/
│       └── service/
│           ├── api/.env      # Service-specific overrides for API
│           ├── web/.env      # Service-specific overrides for Web
│           └── worker/.env   # Service-specific overrides for Worker
├── apps/
│   ├── api/
│   ├── web/
│   └── worker/
└── .env.base                 # Shared base environment
```

### Environment Priority

When a service loads environment variables, it follows this cascade:

1. **Service-specific env** (`.dual/.local/service/{service}/.env`) - Highest priority
2. **Base env** (`.env.base`) - Fallback for unset variables

This allows you to:
- Set common defaults in `.env.base`
- Override specific vars per-context using `dual env set`
- Override specific vars per-service using `dual env set --service`

### The Remapping Process

1. You run: `dual env set DATABASE_URL "postgres://localhost/dev_db"`
2. Dual writes to: `worktrees/dev/.dual/.local/service/{detected-service}/.env`
3. Your app loads: Both `.dual/.local/service/{service}/.env` and `.env.base`
4. Result: App sees `DATABASE_URL=postgres://localhost/dev_db` (from service-specific) and other vars from base

## Quick Start

### Prerequisites

- Node.js installed
- `dual` CLI installed and in your PATH
- Git configured with user name and email

**Note**: This example works best when cloned as a standalone repository:

```bash
git clone https://github.com/lightfastai/dual-env-remapping-example.git
cd dual-env-remapping-example
```

If you're viewing this as a git submodule within the main dual repository, navigate to the `examples/env-remapping` directory and follow the manual usage instructions below.

### Run the Demo

```bash
# Install dependencies for all services
npm install

# Run the automated demo
./demo.sh

# Or run with cleanup at the end
./demo.sh --cleanup
```

The demo script will:
1. Initialize git repository
2. Create multiple worktrees (dev, feature-auth, feature-payments)
3. Set environment variables for each context
4. Show the generated `.dual/.local/service/` structure
5. Display environment files for each service
6. Optionally start servers to demonstrate they work

## Manual Usage

### Step 1: Install Dependencies

```bash
npm install
```

This installs express and dotenv for all three services.

### Step 2: Initialize and Create Worktree

```bash
# Initialize dual (only needed once)
dual init

# Create a worktree for your feature
dual create dev
cd worktrees/dev
```

### Step 3: Set Environment Variables

```bash
# Set global variables (apply to all services in this context)
dual env set DATABASE_URL "postgres://localhost/dev_db"
dual env set DEBUG "true"

# Set service-specific variables
dual env set --service api API_KEY "dev-api-secret"
dual env set --service web REDIS_URL "redis://localhost:6379/1"
```

### Step 4: Verify Environment Files

```bash
# Check what was generated
cat .dual/.local/service/api/.env
cat .dual/.local/service/web/.env
cat .dual/.local/service/worker/.env
```

### Step 5: Start Services

```bash
# Start API service (from worktrees/dev/)
cd apps/api
dual npm start
# API will load vars from ../../.dual/.local/service/api/.env and ../../.env.base

# In another terminal, start web service
cd worktrees/dev/apps/web
dual npm start

# In another terminal, start worker service
cd worktrees/dev/apps/worker
dual npm start
```

### Step 6: Test the Services

```bash
# Check API (will use its assigned port)
curl http://localhost:4101/

# Check Web
curl http://localhost:4102/

# Check Worker
curl http://localhost:4103/
```

Each response will show:
- The service name
- The assigned port
- All environment variables
- Which files the variables were loaded from

## Expected Directory Structure

After running the demo, you'll have:

```
examples/env-remapping/
├── dual.config.yml           # Dual configuration
├── .env.base                 # Base environment variables
├── apps/
│   ├── api/                  # API service
│   │   ├── package.json
│   │   └── server.js
│   ├── web/                  # Web service
│   │   ├── package.json
│   │   └── server.js
│   └── worker/               # Worker service
│       ├── package.json
│       └── server.js
└── worktrees/
    ├── dev/
    │   ├── .dual/
    │   │   └── .local/
    │   │       └── service/
    │   │           ├── api/.env
    │   │           ├── web/.env
    │   │           └── worker/.env
    │   └── apps/             # Service code (linked)
    ├── feature-auth/
    │   ├── .dual/
    │   │   └── .local/
    │   │       └── service/
    │   │           ├── api/.env      # Different values!
    │   │           ├── web/.env
    │   │           └── worker/.env
    │   └── apps/
    └── feature-payments/
        ├── .dual/
        │   └── .local/
        │       └── service/
        │           ├── api/.env      # Different values!
        │           ├── web/.env
        │           └── worker/.env
        └── apps/
```

## Using Generated .env Files in Your Services

The Node.js servers in this example show the recommended pattern:

```javascript
const path = require('path');
const serviceEnvPath = path.join(__dirname, '../../.dual/.local/service/api/.env');
const baseEnvPath = path.join(__dirname, '../../.env.base');

// Load service-specific env first (higher priority)
require('dotenv').config({ path: serviceEnvPath });

// Load base env second (fallback for unset variables)
require('dotenv').config({ path: baseEnvPath });
```

This ensures:
1. Service-specific overrides take precedence
2. Base values are used as fallbacks
3. Your app works even if no overrides are set

## Key Concepts

### Context Isolation

Each worktree is a separate context with its own:
- Git branch
- Port assignments
- Environment variables
- Service configurations

Changes in one worktree don't affect others.

### Service Detection

Dual automatically detects which service you're in based on your current working directory:

```bash
cd apps/api
dual npm start        # Detects "api" service, uses port 4101

cd apps/web
dual npm start        # Detects "web" service, uses port 4102
```

You can also override with `--service` flag:

```bash
dual --service worker npm start
```

### Port Calculation

Ports are assigned deterministically based on:
- **Base port**: Set when creating a context (e.g., 4100 for "dev")
- **Service index**: Services ordered alphabetically
  - api → 4101 (basePort + 1)
  - web → 4102 (basePort + 2)
  - worker → 4103 (basePort + 3)

### Environment Variables

Variables are managed with `dual env`:

```bash
# Set for all services in current context
dual env set KEY "value"

# Set for specific service
dual env set --service api KEY "value"

# List all variables
dual env list

# Remove a variable
dual env unset KEY
```

## Common Use Cases

### Feature Branch Development

```bash
# Create feature worktree
dual create feature-new-ui

# Set feature-specific database
cd worktrees/feature-new-ui
dual env set DATABASE_URL "postgres://localhost/feature_ui_db"

# Work on feature without affecting other contexts
cd apps/web
dual npm start  # Uses feature-specific env and port
```

### Testing Multiple Configurations

```bash
# Dev with production-like settings
dual create dev-prod
cd worktrees/dev-prod
dual env set NODE_ENV "production"
dual env set DEBUG "false"
dual env set LOG_LEVEL "error"

# Dev with debug enabled
dual create dev-debug
cd worktrees/dev-debug
dual env set NODE_ENV "development"
dual env set DEBUG "true"
dual env set LOG_LEVEL "debug"
```

### Service-Specific API Keys

```bash
# Different API keys per service
dual env set --service api STRIPE_KEY "sk_test_api_..."
dual env set --service web STRIPE_KEY "sk_test_web_..."
dual env set --service worker STRIPE_KEY "sk_test_worker_..."
```

## Troubleshooting

### Service-Specific .env Not Created

**Problem**: Running `dual env set` but no `.dual/.local/service/{service}/.env` file appears.

**Solution**:
- Make sure you're in a git worktree created by `dual create`
- Check you're running the command from within the worktree directory
- Verify `dual.config.yml` exists and lists your services

### Environment Variables Not Loading

**Problem**: Service starts but doesn't see the environment variables.

**Solution**:
- Verify the paths in your dotenv.config() calls are correct
- Check that `.dual/.local/service/{service}/.env` exists
- Make sure you're using relative paths from your service directory
- Run `cat .dual/.local/service/{service}/.env` to verify contents

### Port Conflicts

**Problem**: Getting "port already in use" errors.

**Solution**:
- Each worktree gets unique ports automatically
- If you still have conflicts, check for other processes: `lsof -i :4101`
- Base ports are assigned incrementally (4100, 4200, 4300, etc.)

### Can't Find Service

**Problem**: Dual says "service not detected".

**Solution**:
- Ensure you're in a service directory listed in `dual.config.yml`
- Check that the `path` in config matches your actual directory structure
- Use `--service` flag to explicitly specify: `dual --service api npm start`

## Architecture Notes

### Why .dual/.local/service/?

This structure ensures:
- **Worktree isolation**: Each worktree has its own `.dual/.local/` directory
- **Service isolation**: Each service has its own `.env` file
- **Git-friendly**: The `.dual/` directory is in `.gitignore` (local state only)
- **Vercel-proof**: Won't conflict with deployment tools that manage their own `.env` files

### Why Not Write Directly to .env?

Writing to `.env` files in the project root causes problems:
- Deployment tools (like Vercel) might overwrite them
- Changes could accidentally get committed
- No clear separation between base and override values

The `.dual/.local/service/` approach keeps overrides separate and explicit.

### No Hooks Required

Unlike some multi-environment tools, dual's remapping is built-in:
- No pre-command hooks needed
- No shell integration required
- Just use `dual` before your commands

## Real-World Example

Here's a typical workflow for a team member:

```bash
# Start new feature
dual create feature-search
cd worktrees/feature-search

# Use local test database
dual env set DATABASE_URL "postgres://localhost/search_test"

# Enable debug logging
dual env set DEBUG "true"
dual env set LOG_LEVEL "debug"

# Different API key for testing
dual env set --service api ELASTICSEARCH_KEY "test_key_123"

# Start development
cd apps/api
dual npm run dev        # Runs with search_test DB and debug logging

cd ../web
dual npm run dev        # Also uses search_test DB

# Meanwhile, your main dev worktree is unaffected
cd ../../dev/apps/api
dual npm run dev        # Still uses dev_db and production logging
```

## Cleanup

To remove the example and all generated files:

```bash
./demo.sh --cleanup
```

Or manually:

```bash
# Remove worktrees
dual delete dev
dual delete feature-auth
dual delete feature-payments

# Remove node_modules
rm -rf node_modules apps/*/node_modules
```

## Learn More

- [Dual Documentation](https://github.com/lightfastai/dual)
- [Environment Management Guide](https://github.com/lightfastai/dual/docs/environment.md)
- [Worktree Workflows](https://github.com/lightfastai/dual/docs/worktrees.md)

## License

MIT
