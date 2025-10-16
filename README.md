# Dual Environment Remapping Example

This example demonstrates how `dual` manages environment variables across multiple git worktrees using a two-root architecture where environment overrides are shared across all worktrees.

## What This Example Demonstrates

- **Two-Root Architecture**: Environment overrides stored in parent repo, shared by all worktrees
- **Service-Specific Overrides**: Set different env vars for each service using `dual env set --service`
- **Environment Cascading**: Services load vars from base, service-specific, and override files
- **Hook-Based Customization**: Use hooks to set context-specific values (e.g., unique ports, database names)
- **Shared Environment Model**: All worktrees see the same environment overrides from parent repo
- **Built-in Environment Injection**: Use `dual run` to automatically merge all environment layers

## How Environment Remapping Works

### Two-Root Architecture

Dual uses a **two-root architecture** to manage environments across worktrees:

1. **Parent Repository Root**: Stores shared configuration and environment overrides
   - Location: `<parent-repo>/.dual/.local/service/<service>/.env`
   - Contains: Environment variable overrides set via `dual env set`
   - Shared by: ALL worktrees of the same repository

2. **Worktree Root**: Contains the actual service code and base environment
   - Location: `worktrees/dev/apps/<service>/`
   - Contains: Service code, `.env.base` (if configured)
   - Unique to: Each worktree

### File Structure

When you create a worktree and set environment variables, dual creates this structure:

```
examples/env-remapping/              # Parent repo (main repository)
├── .dual/
│   └── .local/
│       └── service/
│           ├── api/.env      # Environment overrides - SHARED by all worktrees
│           ├── web/.env      # Environment overrides - SHARED by all worktrees
│           └── worker/.env   # Environment overrides - SHARED by all worktrees
├── .env.base                 # Base environment (optional)
└── worktrees/
    └── dev/                  # Worktree (references parent's overrides)
        ├── apps/
        │   ├── api/          # Service code
        │   ├── web/
        │   └── worker/
        └── .env.base         # Same as parent (via worktree)
```

**Key Point**: Environment overrides are stored in the **parent repo**, NOT in each worktree. All worktrees share the same overrides.

### Environment Priority

When using `dual run`, environment variables are loaded in this order:

1. **Base environment** (`.env.base`) - Lowest priority
2. **Service-specific env** (`apps/<service>/.env`) - Medium priority
3. **Context overrides** (`<parent-repo>/.dual/.local/service/<service>/.env`) - Highest priority

This allows you to:
- Set common defaults in `.env.base` (shared across all services)
- Set service defaults in `apps/<service>/.env` (per-service defaults)
- Override specific vars using `dual env set` (stored in parent repo, shared by all worktrees)
- Override per-service using `dual env set --service <service>` (also shared by all worktrees)

### The Remapping Process

1. You run: `dual env set DATABASE_URL "postgres://localhost/dev_db"`
2. Dual writes to: `<parent-repo>/.dual/.local/service/<service>/.env` (NOT in the worktree)
3. Your app loads via `dual run`: Merges `.env.base`, `apps/<service>/.env`, and overrides
4. Result: App sees `DATABASE_URL=postgres://localhost/dev_db` (from override) and other vars from base/service files

**Important**: Since overrides are stored in the parent repo, they are **shared across all worktrees**. If you want truly isolated environments per worktree, you'll need to use different approaches (e.g., hook scripts that detect the current branch/context)

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
3. Set environment variables (stored in parent repo's `.dual/.local/service/`)
4. Show the generated environment structure
5. Display environment files from the parent repository
6. Optionally start servers to demonstrate they work

**Note**: This example demonstrates the shared environment architecture - all worktrees use the same environment overrides from the parent repo.

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
# Check what was generated in the PARENT REPO (not in the worktree)
# Navigate back to the parent repo to see the override files
cd ../..  # Back to parent repo
cat .dual/.local/service/api/.env
cat .dual/.local/service/web/.env
cat .dual/.local/service/worker/.env

# These files are shared by ALL worktrees
```

### Step 5: Start Services

```bash
# Start API service (from worktrees/dev/)
cd worktrees/dev/apps/api
dual run npm start
# dual run injects environment from:
#   1. <parent-repo>/.env.base
#   2. <parent-repo>/apps/api/.env
#   3. <parent-repo>/.dual/.local/service/api/.env

# In another terminal, start web service
cd worktrees/dev/apps/web
dual run npm start

# In another terminal, start worker service
cd worktrees/dev/apps/worker
dual run npm start
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
examples/env-remapping/              # Parent repository
├── dual.config.yml                  # Dual configuration
├── .env.base                        # Base environment variables
├── .dual/
│   └── .local/
│       ├── registry.json            # Shared registry for all worktrees
│       └── service/
│           ├── api/.env             # Environment overrides - SHARED by all worktrees
│           ├── web/.env             # Environment overrides - SHARED by all worktrees
│           └── worker/.env          # Environment overrides - SHARED by all worktrees
├── apps/
│   ├── api/                         # API service
│   │   ├── package.json
│   │   └── server.js
│   ├── web/                         # Web service
│   │   ├── package.json
│   │   └── server.js
│   └── worker/                      # Worker service
│       ├── package.json
│       └── server.js
└── worktrees/
    ├── dev/                         # Worktree (uses parent's .dual/...)
    │   ├── apps/                    # Service code (via git worktree)
    │   │   ├── api/
    │   │   ├── web/
    │   │   └── worker/
    │   └── .env.base                # Same file as parent (via git worktree)
    ├── feature-auth/                # Another worktree
    │   ├── apps/
    │   └── .env.base
    └── feature-payments/            # Another worktree
        ├── apps/
        └── .env.base
```

**Key Architecture Points**:
- Environment overrides are in the **parent repo** at `.dual/.local/service/`
- **All worktrees share the same overrides** (no per-worktree isolation)
- Registry is also shared in the parent repo at `.dual/.local/registry.json`
- Worktrees only contain the actual service code (via git worktree mechanism)

## Using Environment Variables in Your Services

### Recommended Approach: Use `dual run`

The **recommended way** to run services with dual is using `dual run`:

```bash
cd apps/api
dual run npm start
```

When you use `dual run`, dual automatically injects the environment from all three layers:
1. Base environment (`.env.base`)
2. Service-specific environment (`apps/api/.env`)
3. Context-specific overrides (`.dual/.local/service/api/.env` from parent repo)

Your application receives the merged environment directly via `process.env` - no need to manually load `.env` files.

### Alternative: Manual .env Loading (Not Recommended)

If you need to load `.env` files manually (not using `dual run`), you would need to:

```javascript
const path = require('path');
// Note: These paths must point to the PARENT REPO, not the worktree
const serviceEnvPath = path.join(__dirname, '../../../../.dual/.local/service/api/.env');
const baseEnvPath = path.join(__dirname, '../../.env.base');

// Load service-specific env first (higher priority)
require('dotenv').config({ path: serviceEnvPath });

// Load base env second (fallback for unset variables)
require('dotenv').config({ path: baseEnvPath });
```

However, this approach is **not recommended** because:
- It requires complex relative paths to reach the parent repo
- You lose the benefit of dual's automatic environment merging
- It's harder to maintain and debug

**Always prefer `dual run` for running services.**

## Full Dotenv Compatibility

Dual now uses the industry-standard `godotenv` library, providing full compatibility with Node.js dotenv features:

### Multiline Values
```bash
# SSL certificates and keys
SSL_CERT="-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAKLdQVPy90WjMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
-----END CERTIFICATE-----"

# SQL queries
QUERY="SELECT * FROM users
WHERE active = true
ORDER BY created_at"
```

### Variable Expansion
```bash
# Reference other variables
BASE_URL=http://localhost:3000
API_URL=${BASE_URL}/api    # Expands to: http://localhost:3000/api
WS_URL=$BASE_URL/ws        # Also expands with $ syntax

# Nested expansion
APP_NAME=MyApp
VERSION=1.0.0
FULL_NAME=${APP_NAME}-${VERSION}  # Expands to: MyApp-1.0.0
```

### Escape Sequences (in double quotes)
```bash
# Newlines
MESSAGE="Line 1\nLine 2\nLine 3"

# Windows paths (backslash escaping)
PATH="C:\\Program Files\\MyApp"

# Embedded quotes
JSON="{\"key\": \"value\"}"
```

### Inline Comments
```bash
# Comments after values are now stripped
PORT=3000 # Application port
HOST=localhost # Development host
```

### Quote Behavior
```bash
# Double quotes: expansion and escapes processed
EXPAND="${BASE_URL}/api"      # Variable expanded
ESCAPED="Hello\nWorld"         # Newline processed

# Single quotes: literal values (no processing)
NO_EXPAND='${BASE_URL}/api'   # Literal: ${BASE_URL}/api
NO_ESCAPE='Hello\nWorld'       # Literal: Hello\nWorld
```

### Migration from Old Parser

If you have existing .env files that relied on the old parser behavior:

1. **Literal ${VAR}**: Use single quotes instead of double
   ```bash
   # Old: API_TEMPLATE="${BASE_URL}/api"  # Was literal
   # New: API_TEMPLATE='${BASE_URL}/api'  # Now literal
   ```

2. **Literal \n**: Use single quotes or escape the backslash
   ```bash
   # Old: MESSAGE="Hello\nWorld"    # Was literal \n
   # New: MESSAGE='Hello\nWorld'    # Keep literal
   # Or:  MESSAGE="Hello\\nWorld"   # Escape the backslash
   ```

3. **Inline comments**: Now properly stripped
   ```bash
   # Old: PORT=3000 # comment    # Value was "3000 # comment"
   # New: PORT=3000 # comment    # Value is "3000"
   ```

See `example-complex.env` for comprehensive examples of all supported features.

## Key Concepts

### Shared Environment Architecture

After the two-root architecture fix (Issue #85), dual now uses a **shared environment** model:

- **Git branch**: Each worktree has its own branch (isolated)
- **Environment overrides**: Stored in parent repo's `.dual/.local/service/` (SHARED across all worktrees)
- **Registry**: Stored in parent repo's `.dual/.local/registry.json` (SHARED across all worktrees)
- **Service code**: Each worktree has its own copy (via git worktree mechanism)

**Important**: Changes to environment overrides (via `dual env set`) affect ALL worktrees because they're stored in the parent repository. If you need per-worktree isolation, consider using hook scripts that set different values based on the current context/branch.

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

### Why Parent Repo Storage?

Environment overrides are stored in the **parent repository's** `.dual/.local/service/` directory (not in worktrees) because:

- **Shared Registry**: Git worktrees share the parent repo's `.git` folder, so dual stores all state in the parent
- **Consistency**: All worktrees see the same registry and environment configuration
- **Simplicity**: One source of truth for environment overrides
- **Git-friendly**: The `.dual/` directory is in `.gitignore` (local state only)

### Why Not Per-Worktree Isolation?

The original design had per-worktree environment files, but this caused issues:
- Worktrees couldn't properly resolve their own `.dual/.local/` directories
- Registry became fragmented across worktrees
- Environment management was inconsistent

The two-root architecture (Issue #85) fixed these issues by centralizing storage in the parent repo.

### Achieving Per-Worktree Isolation

If you need different environment values per worktree, use hook scripts:

```bash
#!/bin/bash
# .dual/hooks/setup-env.sh
# Set different DATABASE_URL based on context name
dual env set DATABASE_URL "postgres://localhost/${DUAL_CONTEXT_NAME}_db"
```

This way, each worktree gets different values even though they're stored in the shared location.

### Using `dual run`

Dual's environment injection is built into `dual run`:
- No manual .env file loading needed
- No shell integration required
- Just use `dual run <command>` to get the merged environment

## Real-World Example

Here's a typical workflow demonstrating the shared environment architecture:

```bash
# Start new feature
dual create feature-search
cd worktrees/feature-search

# Set environment overrides (stored in parent repo, affects ALL worktrees)
dual env set DATABASE_URL "postgres://localhost/search_test"
dual env set DEBUG "true"
dual env set LOG_LEVEL "debug"
dual env set --service api ELASTICSEARCH_KEY "test_key_123"

# Start development
cd apps/api
dual run npm start        # Runs with overrides from parent repo

# Note: If you switch to another worktree, it will see the SAME overrides
cd ../../../dev/apps/api
dual run npm start        # Uses the SAME DATABASE_URL (search_test) because it's shared!
```

**Key Point**: Because environment overrides are stored in the parent repo, changing them in one worktree affects ALL worktrees. For true per-worktree isolation, use hook scripts that set context-specific values based on `$DUAL_CONTEXT_NAME`.

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
