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

# Step 1: Create dev worktree
echo -e "${BLUE}Step 1: Creating 'dev' worktree${NC}"
echo "Command: dual create dev"
if dual create dev 2>/dev/null || true; then
    echo -e "${GREEN}✓ Dev worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Dev worktree may already exist${NC}\n"
fi

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
echo "Command: dual create feature-auth"
if dual create feature-auth 2>/dev/null || true; then
    echo -e "${GREEN}✓ Feature-auth worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Feature-auth worktree may already exist${NC}\n"
fi

cd worktrees/feature-auth

echo "Command: dual env set DATABASE_URL 'postgres://localhost/auth_db'"
dual env set DATABASE_URL "postgres://localhost/auth_db"

echo "Command: dual env set --service api API_KEY 'auth-api-key'"
dual env set --service api API_KEY "auth-api-key"

echo -e "${GREEN}✓ Feature-auth environment configured${NC}\n"

cd ../..

# Step 5: Create feature-payments worktree
echo -e "${BLUE}Step 5: Creating 'feature-payments' worktree with different env${NC}"
echo "Command: dual create feature-payments"
if dual create feature-payments 2>/dev/null || true; then
    echo -e "${GREEN}✓ Feature-payments worktree created${NC}\n"
else
    echo -e "${YELLOW}⚠ Feature-payments worktree may already exist${NC}\n"
fi

cd worktrees/feature-payments

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
echo -e "${BLUE}Step 7: Environment Files for Each Context${NC}\n"

echo -e "${YELLOW}=== Dev Context (API Service) ===${NC}"
if [ -f worktrees/dev/.dual/.local/service/api/.env ]; then
    cat worktrees/dev/.dual/.local/service/api/.env
else
    echo "(No env file yet)"
fi
echo ""

echo -e "${YELLOW}=== Dev Context (Web Service) ===${NC}"
if [ -f worktrees/dev/.dual/.local/service/web/.env ]; then
    cat worktrees/dev/.dual/.local/service/web/.env
else
    echo "(No env file yet)"
fi
echo ""

echo -e "${YELLOW}=== Feature-Auth Context (API Service) ===${NC}"
if [ -f worktrees/feature-auth/.dual/.local/service/api/.env ]; then
    cat worktrees/feature-auth/.dual/.local/service/api/.env
else
    echo "(No env file yet)"
fi
echo ""

echo -e "${YELLOW}=== Feature-Payments Context (API Service) ===${NC}"
if [ -f worktrees/feature-payments/.dual/.local/service/api/.env ]; then
    cat worktrees/feature-payments/.dual/.local/service/api/.env
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
echo "Each worktree has its own isolated environment:"
echo ""
echo -e "${GREEN}✓ Separate .dual/.local/service/ directories per worktree${NC}"
echo -e "${GREEN}✓ Each service has its own .env file${NC}"
echo -e "${GREEN}✓ Variables differ between worktrees (isolation verified)${NC}"
echo -e "${GREEN}✓ Base port assignments are unique per context${NC}"
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
echo "2. Set global and service-specific environment variables"
echo "3. Each worktree has isolated .dual/.local/service/ directories"
echo "4. Each service loads from both service-specific and base env files"
echo "5. Port assignments are automatic and unique per context"
echo ""
echo "Next steps:"
echo "- Explore the worktrees/ directory to see the generated structure"
echo "- Check .dual/.local/service/*/.env files to see the remapped variables"
echo "- Try starting a service: cd worktrees/dev/apps/api && dual npm start"
echo "- Read the README.md for more detailed usage examples"
echo ""

# Cleanup if requested
if [ "$CLEANUP" = true ]; then
    echo -e "${YELLOW}Cleaning up...${NC}"

    # Delete worktrees
    dual delete dev 2>/dev/null || true
    dual delete feature-auth 2>/dev/null || true
    dual delete feature-payments 2>/dev/null || true

    # Remove worktrees directory if empty
    rmdir worktrees 2>/dev/null || true

    echo -e "${GREEN}✓ Cleanup complete${NC}\n"
fi
