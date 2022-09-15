###########
# Les commandes "make xxx" vont s'exécuter dans un docker déjà lancé.
# Le nom du docker est renseigné ligne 15
###########


# Parameters
SHELL         = bash
PROJECT_NAME  = prefix
BASE_URL      = http://localhost/$(PROJECT_NAME)
PHPSTAN_LEVEL = 8

# Docker
DOCKER_COMP   = docker-compose
DOCKER        = $(DOCKER_COMP) exec nomducontainer

# Executables
EXEC_PHP      = $(DOCKER) php -d xdebug.enable=0 -d memory_limit=-1
EXEC_PHP_XDBG = $(DOCKER) php -d xdebug.enable=1 -d xdebug.mode=coverage -d memory_limit=-1
COMPOSER      = $(DOCKER) composer

# Shortcuts
SYMFONY       = $(EXEC_PHP) bin/console

# Vendors
PHPUNIT       = $(EXEC_PHP) vendor/bin/phpunit
PHPUNIT_COV   = $(EXEC_PHP_XDBG) vendor/bin/phpunit
PARATEST      = $(EXEC_PHP) vendor/bin/paratest
PHPSTAN       = $(EXEC_PHP) vendor/bin/phpstan
PHP_CS_FIXER  = $(DOCKER) vendor/bin/php-cs-fixer

# Misc
.DEFAULT_GOAL = help
.PHONY        : vendor assets

## —— Makefile —————————————————————————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker ———————————————————————————————————————————————————————————————————
bash: ## Log to the docker container
	@$(DOCKER) bash

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands
	@$(SYMFONY)

cc: ## Clean cache
	$(eval env ?= 'dev')
	@$(SYMFONY) c:c --env=$(env)

cw: ## Cache warmup
	$(eval env ?= 'dev')
	@$(SYMFONY) c:w --env=$(env)

purge: ## Purge cache and logs
	@$(DOCKER) rm -rf var/cache/* var/log/*

## —— Project ——————————————————————————————————————————————————————————————————
load-fixtures: ## Build the DB, control the schema validity, load fixtures and check the migration status (deb)
	$(eval env ?= 'dev')
	@echo " > env : $(env)"
	@$(SYMFONY) doctrine:database:drop --env=$(env) --force
	@$(SYMFONY) doctrine:database:create --env=$(env)
	@$(SYMFONY) doctrine:schema:create --env=$(env)
	@echo " Loading fixtures..."
	@$(SYMFONY) hautelook:fixtures:load --no-interaction --env=$(env)
	@echo " > Done! ✅"

load-test-fixtures: env=test
load-test-fixtures: load-fixtures

create-db-and-migrate: ## Build the DB from the Doctrine migrations
	$(eval env ?= 'dev')
	@echo " > env : $(env)"
	@$(SYMFONY) doctrine:database:drop --env=$(env) --force
	@$(SYMFONY) doctrine:database:create --env=$(env)
	@$(SYMFONY) doctrine:migrations:migrate --env=$(env) --no-interaction
	@echo " Loading fixtures..."
	@$(SYMFONY) hautelook:fixtures:load --no-interaction --env=$(env)
	@echo " > Done! ✅"

## —— Tests ✅ —————————————————————————————————————————————————————————————————
test: ## Run all tests with an optional filter
	@$(eval testsuite ?= 'all')
	@$(eval filter ?= '.')
	@$(eval options ?=--stop-on-failure)
	@$(PHPUNIT) --testsuite=$(testsuite) --filter=$(filter) $(options)

test-complete: ## Run all tests without stopping on first error
test-complete: options=
test-complete: test

test-debug: ## Run tests with debug output
test-debug: options=--debug --stop-on-failure
test-debug: test

test-unit: ## Run unit tests only
test-unit: testsuite=unit
test-unit: test

test-integration: ## Run integration tests only
test-integration: testsuite=integration
test-integration: test

test-db: ## Run database tests only
test-db: testsuite=db
test-db: test

test-functional: ## Run functional tests only
test-functional: testsuite=functional
test-functional: test

para-test: ## Run all tests with "p" parallel processes
	$(eval p ?= 1)
	@$(PARATEST) -p$(p) --verbose

coverage: ## Generate the code coverage HTML report locally
	@$(PHPUNIT_COV) --coverage-html=var/coverage

## —— Static analysis ✨ ———————————————————————————————————————————————————————
static: stan ## Run the static analysis (PHPStan)

stan: ## Run PHPStan
	@$(eval level ?= $(PHPSTAN_LEVEL))  # with a given level
	@$(eval path ?=)     # with a given file/directory
	@echo ✨ PHPStan ✨ @ level $(level) path=$(path)
	@$(PHPSTAN) analyse --level $(level) $(path)

## —— Coding standards ✨ ——————————————————————————————————————————————————————
lint-php: ## Lint files with php-cs-fixer
	@$(PHP_CS_FIXER) fix --dry-run

fix-php: ## Fix files with php-cs-fixer
	@$(PHP_CS_FIXER) fix

## —— Composer 🧙‍♂️ ————————————————————————————————————————————————————————————
composer-up: ## Update composer packages
	@$(COMPOSER) update
