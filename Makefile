FRONTEND_DIR := apps/frontend
BACKEND_DIR := apps/backend

# ------------------------------
# Frontend CI targets
# ------------------------------
.PHONY: frontend-install frontend-format frontend-format-fix frontend-lint frontend-lint-fix frontend-typecheck frontend-test frontend-ci

frontend-install:
	pnpm --dir $(FRONTEND_DIR) install --frozen-lockfile

frontend-format:
	pnpm --dir $(FRONTEND_DIR) run format

frontend-format-fix:
	pnpm --dir $(FRONTEND_DIR) run format:fix

frontend-lint:
	pnpm --dir $(FRONTEND_DIR) run lint

frontend-lint-fix:
	pnpm --dir $(FRONTEND_DIR) run lint:fix

frontend-typecheck:
	pnpm --dir $(FRONTEND_DIR) run typecheck

frontend-test:
	pnpm --dir $(FRONTEND_DIR) run test:run

frontend-ci: frontend-format frontend-lint frontend-typecheck frontend-test

# ------------------------------
# Backend CI targets
# ------------------------------
.PHONY: backend-install backend-format backend-format-fix backend-lint backend-lint-fix backend-typecheck backend-test backend-ci

backend-install:
	uv --directory $(BACKEND_DIR) sync --frozen --group dev

backend-format:
	uv --directory $(BACKEND_DIR) run ruff format --check app

backend-format-fix:
	uv --directory $(BACKEND_DIR) run ruff format app

backend-lint:
	uv --directory $(BACKEND_DIR) run ruff check app

backend-lint-fix:
	uv --directory $(BACKEND_DIR) run ruff check --fix app

backend-typecheck:
	uv --directory $(BACKEND_DIR) run pyright app

backend-test:
	uv --directory $(BACKEND_DIR) run pytest

backend-ci: backend-format backend-lint backend-typecheck
