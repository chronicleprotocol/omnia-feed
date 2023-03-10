build:
	docker build -t omnia .
.PHONY: build

build-dev:
	docker build -t ghcr.io/chronicleprotocol/omnia:dev .
.PHONY: build-dev

run:
	docker-compose up -d
.PHONY: run

build-and-run: build run
	@echo "Ran."
.PHONY: build-and-run

build-test-e2e:
	docker-compose -f .github/docker-compose-e2e-tests.yml build --no-cache omnia_e2e_dev
.PHONY: build-test-e2e

run-test-e2e:
	docker-compose -f .github/docker-compose-e2e-tests.yml run --rm omnia_e2e_dev
.PHONY: run-test-e2e

test: build-dev build-test-e2e # Run tests 
	docker-compose -f .github/docker-compose-e2e-tests.yml run omnia_e2e
.PHONY: test
