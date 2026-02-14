FRONTEND_DIR := apps/frontend
BACKEND_DIR := apps/backend
DOCKER_WEB_NAME ?= 3pull-web
DOCKER_API_NAME ?= 3pull-api
DOCKER_IMAGE_TAG ?= latest
DOCKER_NETWORK_NAME ?= 3pull-net

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
# Container targets
# ------------------------------
.PHONY: docker-build-web docker-build-api docker-build

docker-build-web:
	docker buildx build --load -f docker/web.Dockerfile -t $(DOCKER_WEB_NAME):$(DOCKER_IMAGE_TAG) .

docker-build-api:
	docker buildx build --load -f docker/api.Dockerfile -t $(DOCKER_API_NAME):$(DOCKER_IMAGE_TAG) .

docker-build: docker-build-web docker-build-api

# ------------------------------
# Startup targets
# ------------------------------
.PHONY: frontend-start frontend-build frontend-prod-start backend-start backend-prod-start up-dev up up-docker down-docker

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

up-docker: docker-build
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)
	@if [ "$$OS" = "Windows_NT" ] && command -v powershell.exe >/dev/null 2>&1; then \
		powershell.exe -NoProfile -Command "Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; docker rm -f $(DOCKER_API_NAME) 2>$$null; docker run --rm --name $(DOCKER_API_NAME) --network $(DOCKER_NETWORK_NAME) --env-file apps/backend/.env -p 8000:8000 $(DOCKER_API_NAME):$(DOCKER_IMAGE_TAG)'; Start-Process powershell -ArgumentList '-NoExit','-Command','cd ''$(CURDIR)''; docker rm -f $(DOCKER_WEB_NAME) 2>$$null; docker run --rm --name $(DOCKER_WEB_NAME) --network $(DOCKER_NETWORK_NAME) --env-file apps/frontend/.env -p 3000:3000 $(DOCKER_WEB_NAME):$(DOCKER_IMAGE_TAG)'"; \
	elif [ "$$(uname -s)" = "Darwin" ] && command -v osascript >/dev/null 2>&1; then \
		osascript \
			-e 'tell application "Terminal" to activate' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && docker rm -f $(DOCKER_API_NAME) >/dev/null 2>&1 || true && docker run --rm --name $(DOCKER_API_NAME) --network $(DOCKER_NETWORK_NAME) --env-file apps/backend/.env -p 8000:8000 $(DOCKER_API_NAME):$(DOCKER_IMAGE_TAG)"' \
			-e 'tell application "Terminal" to do script "cd $(CURDIR) && docker rm -f $(DOCKER_WEB_NAME) >/dev/null 2>&1 || true && docker run --rm --name $(DOCKER_WEB_NAME) --network $(DOCKER_NETWORK_NAME) --env-file apps/frontend/.env -p 3000:3000 $(DOCKER_WEB_NAME):$(DOCKER_IMAGE_TAG)"'; \
	else \
		echo "up-docker supports macOS Terminal (osascript) and Windows PowerShell."; \
		exit 1; \
	fi

down-docker:
	@docker rm -f $(DOCKER_WEB_NAME) >/dev/null 2>&1 || true
	@docker rm -f $(DOCKER_API_NAME) >/dev/null 2>&1 || true
	@docker network rm $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || true
