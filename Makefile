setup:
	@echo "Setting up virtual environment"
	poetry shell

install:
	@echo "Installing dependencies"
	poetry install 

format:
	@echo "Formating code"
	chmod +x ./format.sh
	./format.sh

lint:
	@echo "Liting code"
	chmod +x ./lint.sh
	./lint.sh

test:
	@echo "Running tests"
	chmod +x ./test.sh
	./test.sh

run-app:
	@echo "Running local app with uvicorn"
	uvicorn webapp.main:app --host 0.0.0.0 

docker-build:
	@echo "Building Docker container"
	docker build -t app .

docker-run:
	@echo "Starting Docker container"
	docker run app 

all: install format lint