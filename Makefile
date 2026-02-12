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

backend-ci: backend-format backend-lint backend-typecheck backend-test

# ------------------------------
# Monorepo CI targets
# ------------------------------
.PHONY: all-install all-ci

all-install: frontend-install backend-install

all-ci: all-install frontend-ci backend-ci

# ------------------------------
# Startup targets
# ------------------------------
.PHONY: frontend-start frontend-build frontend-prod-start backend-start backend-prod-start up-dev up

frontend-start:
	pnpm --dir $(FRONTEND_DIR) dev

frontend-build:
	pnpm --dir $(FRONTEND_DIR) build

frontend-prod-start:
	pnpm --dir $(FRONTEND_DIR) start

backend-start:
	uv --directory $(BACKEND_DIR) run uvicorn app.main:app --reload --host 0.0.0.0

backend-prod-start:
	uv --directory $(BACKEND_DIR) run gunicorn -k uvicorn.workers.UvicornWorker app.main:app \
		--bind 0.0.0.0:8000 \
		--workers $${GUNICORN_WORKERS:-2} \
		--threads $${GUNICORN_THREADS:-1} \
		--timeout $${GUNICORN_TIMEOUT:-60} \
		--keep-alive $${GUNICORN_KEEPALIVE:-5}

up-dev: all-install
	@if [ "$$OS" = "Windows_NT" ] && command -v powershell.exe >/dev/null 2>&1; then \
		powershell.exe -NoProfile -Command "Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; make frontend-start'; Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; make backend-start'"; \
	elif [ "$$(uname -s)" = "Darwin" ] && command -v osascript >/dev/null 2>&1; then \
		osascript \
			-e 'tell application "Terminal" to activate' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && make frontend-start"' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && make backend-start"'; \
	else \
		echo "up-dev supports macOS Terminal (osascript) and Windows PowerShell."; \
		exit 1; \
	fi

up: all-install frontend-build
	@if [ "$$OS" = "Windows_NT" ] && command -v powershell.exe >/dev/null 2>&1; then \
		powershell.exe -NoProfile -Command "Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; make frontend-prod-start'; Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; make backend-prod-start'"; \
	elif [ "$$(uname -s)" = "Darwin" ] && command -v osascript >/dev/null 2>&1; then \
		osascript \
			-e 'tell application "Terminal" to activate' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && make frontend-prod-start"' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && make backend-prod-start"'; \
	else \
		echo "up supports macOS Terminal (osascript) and Windows PowerShell."; \
		exit 1; \
	fi
