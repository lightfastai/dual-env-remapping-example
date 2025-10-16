# Two-Root Architecture Explanation

This document explains the two-root architecture implemented in dual after the fix for GitHub Issue #85.

## The Problem (Before Issue #85)

Previously, dual attempted to store environment override files in each worktree's `.dual/.local/service/` directory. This caused several issues:

1. **Path Resolution**: Worktrees couldn't properly resolve their own `.dual/.local/` directories
2. **Registry Fragmentation**: Each worktree had its own registry, causing inconsistencies
3. **Environment Management**: Difficult to track which worktree had which overrides
4. **Complexity**: Managing per-worktree state was complex and error-prone

## The Solution (Two-Root Architecture)

The fix introduced a **two-root architecture** where state is separated between:

### Root 1: Parent Repository (Shared State)
Location: `<parent-repo>/.dual/.local/`

Contains:
- `registry.json` - Context registry (shared by all worktrees)
- `service/<service>/.env` - Environment overrides (shared by all worktrees)

**Key Point**: ALL worktrees share this state because git worktrees share the parent repo's `.git` folder.

### Root 2: Worktree (Code)
Location: `worktrees/<context-name>/`

Contains:
- Service code (via git worktree mechanism)
- `.env.base` (if configured, same file as parent via git)
- `apps/<service>/.env` (service-specific defaults, same as parent via git)

## Environment Loading Priority

When you run a service with `dual run`, dual merges environment from three layers:

```
1. .env.base                                    (lowest priority)
2. apps/<service>/.env                          (medium priority)
3. <parent-repo>/.dual/.local/service/<service>/.env  (highest priority)
```

## Shared vs Isolated

### What's Shared (Same for All Worktrees)
- Environment overrides (set via `dual env set`)
- Registry (context list and metadata)
- Service definitions (from `dual.config.yml`)

### What's Isolated (Different per Worktree)
- Git branch
- Working directory changes
- Service code (each worktree has its own copy)

## Achieving Per-Worktree Environment Isolation

Even though overrides are stored in a shared location, you can achieve per-worktree isolation using **hook scripts**.

### Example: Context-Specific Database URLs

```bash
#!/bin/bash
# .dual/hooks/setup-env.sh

# Use DUAL_CONTEXT_NAME to create unique values
dual env set DATABASE_URL "postgres://localhost/${DUAL_CONTEXT_NAME}_db"
dual env set --service api PORT "${BASE_PORT_FOR_CONTEXT}"
```

This way:
- `dev` worktree gets: `postgres://localhost/dev_db`
- `feature-auth` worktree gets: `postgres://localhost/feature-auth_db`
- `feature-payments` worktree gets: `postgres://localhost/feature-payments_db`

Even though these values are stored in the shared parent repo location, they're **context-specific** because they include the context name.

## File Locations Reference

```
examples/env-remapping/                    # Parent repository
├── .dual/
│   └── .local/
│       ├── registry.json                  # SHARED: Context registry
│       └── service/
│           ├── api/.env                   # SHARED: API overrides
│           ├── web/.env                   # SHARED: Web overrides
│           └── worker/.env                # SHARED: Worker overrides
├── .env.base                              # Base environment (via git)
├── apps/
│   ├── api/.env                           # Service defaults (via git)
│   ├── web/.env
│   └── worker/.env
└── worktrees/
    ├── dev/                               # Worktree (uses parent's .dual/)
    │   ├── apps/                          # Service code (via git worktree)
    │   └── .env.base                      # Same as parent (via git)
    └── feature-auth/                      # Another worktree
        ├── apps/
        └── .env.base
```

## Benefits of Two-Root Architecture

1. **Consistency**: One source of truth for registry and overrides
2. **Simplicity**: No complex per-worktree state management
3. **Reliability**: File paths are predictable and consistent
4. **Flexibility**: Hooks can still provide per-worktree customization
5. **Git-Friendly**: `.dual/` is gitignored, state is never committed

## Migration Notes

If you used dual before Issue #85, note these changes:

1. **Override Location Changed**:
   - Old: `worktrees/<name>/.dual/.local/service/<service>/.env`
   - New: `<parent-repo>/.dual/.local/service/<service>/.env`

2. **Overrides Are Shared**: Changes in one worktree affect all worktrees

3. **Use Hooks for Isolation**: Implement context-specific values in hook scripts

## See Also

- [README.md](./README.md) - Full example documentation
- [.dual/hooks/port-remap.sh](./.dual/hooks/port-remap.sh) - Example hook script
- GitHub Issue #85 - Original bug report and fix
