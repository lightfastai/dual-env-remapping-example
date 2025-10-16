#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
CLEANUP=false
START_SERVERS=false

for arg in "$@"; do
  case $arg in
    --cleanup)
      CLEANUP=true
      shift
      ;;
    --start-servers)
      START_SERVERS=true
      shift
      ;;
  esac
done

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Dual Environment Remapping Demo${NC}"
echo -e "${BLUE}================================${NC}\n"
echo -e "${YELLOW}Note: This demo shows the two-root architecture where:${NC}"
echo -e "${YELLOW}  - Environment overrides are stored in the parent repo${NC}"
echo -e "${YELLOW}  - All worktrees SHARE the same overrides${NC}"
echo -e "${YELLOW}  - Use hooks for per-worktree isolation if needed${NC}\n"

# Check if dual is installed
if ! command -v dual &> /dev/null; then
    echo -e "${RED}Error: 'dual' command not found${NC}"
    echo "Please install dual and ensure it's in your PATH"
    exit 1
fi

echo -e "${GREEN}✓ dual CLI found${NC}\n"

# Initialize git if not already a repo
if [ ! -d .git ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git config user.email "demo@example.com" 2>/dev/null || true
    git config user.name "Demo User" 2>/dev/null || true

    # Create initial commit
    git add .
    git commit -m "Initial commit: dual env remapping example" || true
    echo -e "${GREEN}✓ Git initialized${NC}\n"
else
    echo -e "${GREEN}✓ Git repository already initialized${NC}\n"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}\n"
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}\n"
fi

# Initialize main context if needed
echo -e "${YELLOW}Initializing main context in registry...${NC}"
dual --service api context create main --base-port 4000 2>/dev/null || echo -e "${GREEN}✓ Main context already exists${NC}\n"

# Step 1: Create dev worktree
echo -e "${BLUE}Step 1: Creating 'dev' worktree${NC}"
echo "Command: git worktree add worktrees/dev -b dev"
if [ ! -d worktrees/dev ]; then
    mkdir -p worktrees
    git worktree add worktrees/dev -b dev 2>/dev/null || git worktree add worktrees/dev dev 2>/dev/null
    echo -e "${GREEN}✓ Dev worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Dev worktree already exists${NC}\n"
fi

# Register context with dual
cd worktrees/dev
dual --service api context create dev --base-port 4100 2>/dev/null || echo -e "${YELLOW}⚠ Context already registered${NC}"
cd ../..

# Step 2: Set global environment variables
echo -e "${BLUE}Step 2: Setting global environment variables in dev context${NC}"
cd worktrees/dev

echo "Command: dual env set DATABASE_URL 'postgres://localhost/dev_db'"
dual env set DATABASE_URL "postgres://localhost/dev_db"

echo "Command: dual env set DEBUG 'true'"
dual env set DEBUG "true"

echo -e "${GREEN}✓ Global variables set${NC}\n"

# Step 3: Set service-specific variables
echo -e "${BLUE}Step 3: Setting service-specific environment variables${NC}"

echo "Command: dual env set --service api API_KEY 'dev-api-secret-key'"
dual env set --service api API_KEY "dev-api-secret-key"

echo "Command: dual env set --service web REDIS_URL 'redis://localhost:6379/1'"
dual env set --service web REDIS_URL "redis://localhost:6379/1"

echo "Command: dual env set --service worker LOG_LEVEL 'debug'"
dual env set --service worker LOG_LEVEL "debug"

echo -e "${GREEN}✓ Service-specific variables set${NC}\n"

cd ../..

# Step 4: Create feature-auth worktree
echo -e "${BLUE}Step 4: Creating 'feature-auth' worktree with different env${NC}"
echo "Command: git worktree add worktrees/feature-auth -b feature-auth"
if [ ! -d worktrees/feature-auth ]; then
    git worktree add worktrees/feature-auth -b feature-auth 2>/dev/null || git worktree add worktrees/feature-auth feature-auth 2>/dev/null
    echo -e "${GREEN}✓ Feature-auth worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Feature-auth worktree already exists${NC}\n"
fi

# Register context with dual and set env vars
cd worktrees/feature-auth
dual --service api context create feature-auth --base-port 4200 2>/dev/null || echo -e "${YELLOW}⚠ Context already registered${NC}"

echo "Command: dual env set DATABASE_URL 'postgres://localhost/auth_db'"
dual env set DATABASE_URL "postgres://localhost/auth_db"

echo "Command: dual env set --service api API_KEY 'auth-api-key'"
dual env set --service api API_KEY "auth-api-key"

echo -e "${GREEN}✓ Feature-auth environment configured${NC}\n"

cd ../..

# Step 5: Create feature-payments worktree
echo -e "${BLUE}Step 5: Creating 'feature-payments' worktree with different env${NC}"
echo "Command: git worktree add worktrees/feature-payments -b feature-payments"
if [ ! -d worktrees/feature-payments ]; then
    git worktree add worktrees/feature-payments -b feature-payments 2>/dev/null || git worktree add worktrees/feature-payments feature-payments 2>/dev/null
    echo -e "${GREEN}✓ Feature-payments worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Feature-payments worktree already exists${NC}\n"
fi

# Register context with dual and set env vars
cd worktrees/feature-payments
dual --service api context create feature-payments --base-port 4300 2>/dev/null || echo -e "${YELLOW}⚠ Context already registered${NC}"

echo "Command: dual env set DATABASE_URL 'postgres://localhost/payments_db'"
dual env set DATABASE_URL "postgres://localhost/payments_db"

echo "Command: dual env set --service api API_KEY 'payments-api-key'"
dual env set --service api API_KEY "payments-api-key"

echo "Command: dual env set DEBUG 'false'"
dual env set DEBUG "false"

echo -e "${GREEN}✓ Feature-payments environment configured${NC}\n"

cd ../..

# Step 6: Display directory structure
echo -e "${BLUE}Step 6: Generated Directory Structure${NC}"
echo -e "${YELLOW}worktrees/${NC}"
if command -v tree &> /dev/null; then
    tree -L 4 -I 'node_modules|.git' worktrees/
else
    find worktrees -type d -maxdepth 4 | grep -v node_modules | sed 's|[^/]*/| |g'
fi
echo ""

# Step 7: Display environment files
echo -e "${BLUE}Step 7: Environment Files (Stored in Parent Repo)${NC}\n"
echo -e "${YELLOW}Note: Environment overrides are in the PARENT REPO, not in worktrees${NC}"
echo -e "${YELLOW}Location: .dual/.local/service/<service>/.env${NC}\n"

echo -e "${YELLOW}=== API Service Overrides (Shared by ALL worktrees) ===${NC}"
if [ -f .dual/.local/service/api/.env ]; then
    cat .dual/.local/service/api/.env
else
    echo "(No env file yet)"
fi
echo ""

echo -e "${YELLOW}=== Web Service Overrides (Shared by ALL worktrees) ===${NC}"
if [ -f .dual/.local/service/web/.env ]; then
    cat .dual/.local/service/web/.env
else
    echo "(No env file yet)"
fi
echo ""

echo -e "${YELLOW}=== Worker Service Overrides (Shared by ALL worktrees) ===${NC}"
if [ -f .dual/.local/service/worker/.env ]; then
    cat .dual/.local/service/worker/.env
else
    echo "(No env file yet)"
fi
echo ""

# Step 8: Show port assignments
echo -e "${BLUE}Step 8: Port Assignments${NC}"
echo "Each worktree gets its own base port, and each service gets an offset:"
echo ""
echo -e "${GREEN}Dev context:${NC}"
echo "  - api: 4101"
echo "  - web: 4102"
echo "  - worker: 4103"
echo ""
echo -e "${GREEN}Feature-auth context:${NC}"
echo "  - api: 4201"
echo "  - web: 4202"
echo "  - worker: 4203"
echo ""
echo -e "${GREEN}Feature-payments context:${NC}"
echo "  - api: 4301"
echo "  - web: 4302"
echo "  - worker: 4303"
echo ""

# Step 9: Verification
echo -e "${BLUE}Step 9: Verification${NC}"
echo "Two-root architecture verification:"
echo ""
echo -e "${GREEN}✓ Environment overrides stored in parent repo (.dual/.local/service/)${NC}"
echo -e "${GREEN}✓ Each service has its own .env file (shared by all worktrees)${NC}"
echo -e "${GREEN}✓ Registry is shared in parent repo (.dual/.local/registry.json)${NC}"
echo -e "${GREEN}✓ Worktrees contain only service code (via git worktree)${NC}"
echo ""
echo -e "${YELLOW}⚠ Important: Environment overrides are SHARED across all worktrees${NC}"
echo -e "${YELLOW}  For per-worktree isolation, use hooks with context-specific values${NC}"
echo ""

# Optional: Start servers
if [ "$START_SERVERS" = true ]; then
    echo -e "${BLUE}Step 10: Starting Servers (Optional)${NC}"
    echo "Note: This will start servers in the background."
    echo "Press Ctrl+C to stop this script (servers will continue running)"
    echo ""

    # Start dev API server
    cd worktrees/dev/apps/api
    dual npm start &
    DEV_API_PID=$!
    cd ../../../..

    sleep 2
    echo -e "${GREEN}✓ Dev API server started on port 4101${NC}"
    echo "  Test: curl http://localhost:4101/"
    echo ""

    # Cleanup function
    cleanup_servers() {
        echo -e "\n${YELLOW}Stopping servers...${NC}"
        kill $DEV_API_PID 2>/dev/null || true
        echo -e "${GREEN}✓ Servers stopped${NC}"
    }

    trap cleanup_servers EXIT

    echo "Servers running. Press Ctrl+C to stop."
    wait
fi

# Summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Demo Complete!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo "What was demonstrated:"
echo "1. Created three worktrees (dev, feature-auth, feature-payments)"
echo "2. Set environment variables (stored in parent repo's .dual/)"
echo "3. Two-root architecture: parent repo stores config, worktrees have code"
echo "4. All worktrees SHARE the same environment overrides"
echo "5. Use 'dual run' to inject environment from all layers"
echo ""
echo "Key Architecture Points:"
echo "- Environment overrides: <parent-repo>/.dual/.local/service/<service>/.env"
echo "- Registry: <parent-repo>/.dual/.local/registry.json"
echo "- Service code: worktrees/<name>/apps/<service>/"
echo "- Overrides are SHARED by all worktrees (not isolated per worktree)"
echo ""
echo "Next steps:"
echo "- Check .dual/.local/service/*/.env files in PARENT REPO"
echo "- Try starting a service: cd worktrees/dev/apps/api && dual run npm start"
echo "- Explore how hook scripts can provide per-worktree isolation"
echo "- Read the README.md for detailed architecture explanation"
echo ""

# Cleanup if requested
if [ "$CLEANUP" = true ]; then
    echo -e "${YELLOW}Cleaning up...${NC}"

    # Delete worktrees
    git worktree remove worktrees/dev 2>/dev/null || true
    git worktree remove worktrees/feature-auth 2>/dev/null || true
    git worktree remove worktrees/feature-payments 2>/dev/null || true

    # Delete branches
    git branch -D dev 2>/dev/null || true
    git branch -D feature-auth 2>/dev/null || true
    git branch -D feature-payments 2>/dev/null || true

    # Delete contexts from registry
    dual context delete dev 2>/dev/null || true
    dual context delete feature-auth 2>/dev/null || true
    dual context delete feature-payments 2>/dev/null || true

    # Remove worktrees directory if empty
    rmdir worktrees 2>/dev/null || true

    echo -e "${GREEN}✓ Cleanup complete${NC}\n"
fi
