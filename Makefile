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
	poetry run uvicorn src.app.main:app --reload --host 127.0.0.1 --port 8000

docker-build:
	@echo "Building Docker container"
	docker build -t app .

docker-run:
	@echo "Starting Docker container"
	docker run -p 8000:8000 app 

aws-deploy:
	@echo "Deploying to AWS"
	chmod +x ./scripts/deploy.sh
	./scripts/deploy.sh

tf-init:
	@echo "Initializing Terraform <Initialize the provider with plugin>"
	cd terraform && terraform init

tf-plan:
	@echo "Planning Terraform <Preview of resources to be created>"
	cd terraform && terraform plan

tf-outp:
	@echo "Output Terraform <Output of resources to be created>"
	cd terraform && terraform output

tf-migrate:
	@echo "Migrating Terraform state to remote backend"
	cd terraform && terraform init -migrate-state

tf-apply:
	@echo "Applying Terraform <Create infrastruture resources>"
	cd terraform && terraform apply -auto-approve

tf-destroy:
	@echo "Destroying Terraform <Destroy infrastruture resources>"
	cd terraform && terraform destroy

tf-fmt:
	@echo "Formating Terraform <Auto-format Terraform code>"
	cd terraform && terraform fmt

tf-val:
	@echo "Validating Terraform <Validate Terraform code>"
	cd terraform && terraform validate
	
tf-graph:
	@echo "Graph Terraform <Graph Terraform code>"
	cd terraform && mkdir -p visualize && terraform graph | dot -Tsvg > visualize/graph.svg

tf-plan-json:
	@echo "Graph Terraform <Graph Terraform code>"
	cd terraform && mkdir -p visualize && terraform plan -out=plan.out && terraform show -json plan.out > visualize/plan.json

tf-deploy:
	@echo "Deploying Terraform <Deploy infrastruture resources>"
	cd terraform && terraform init && terraform apply -auto-approve

tf-upload:
	@echo "Uploading Terraform <Upload infrastruture resources>"
	cd terraform && terraform init 
	chmod +x ./scripts/upload_state.sh
	./scripts/upload_state.sh 
	cd terraform && terraform init -migrate-state
	cd terraform && terraform refresh

tf-mgt:
	@echo "Migrating Terraform <Migrate infrastruture resources>"
	cd terraform && terraform init -migrate-state
	cd terraform && terraform refresh

tf-refresh:
	@echo "Refreshing Terraform <Refresh infrastruture resources>"
	cd terraform && terraform refresh
	
all: install format lint
