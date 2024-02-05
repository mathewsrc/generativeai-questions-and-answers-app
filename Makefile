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
	poetry run uvicorn src.app.main:app --host 127.0.0.1 --port 8000

ask:
	@echo "Running local app with ask"
	curl -X POST http://localhost:8000/ask -H "Content-Type: application/json" -d '{"question":"What is the test day?"}'

docker-inspect:
	@echo "Inspecting Docker container"
	docker inspect app

docker-build:
	@echo "Building Docker container"
	docker build -t app .

docker-run:
	@echo "Starting Docker container"
	chmod +x ./scripts/docker_run.sh
	./scripts/docker_run.sh

aws-deploy:
	@echo "Deploying to AWS"
	chmod +x ./scripts/deploy.sh
	./scripts/deploy.sh

hf-del-cache:
	@echo "Deleting downloaded models"
	huggingface-cli delete-cache

tf-init:
	@echo "Initializing Terraform <Initialize the provider with plugin>"
	chmod +x ./scripts/terraform_init.sh
	./scripts/terraform_init.sh

tf-plan:
	@echo "Planning Terraform <Preview of resources to be created>"
	cd terraform/ && terraform plan -input=false 

tf-outp:
	@echo "Output Terraform <Output of resources to be created>"
	cd terraform && terraform output

tf-destroy:
	@echo "Destroying Terraform <Destroy infrastruture resources>"
	cd terraform && terraform destroy

tf-fmt:
	@echo "Formating Terraform <Auto-format Terraform code>"
	cd terraform && terraform fmt -recursive

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
	cd terraform && terraform fmt -recursive && terraform validate && terraform apply -auto-approve -input=false

tf-upload:
	@echo "Uploading Terraform <Upload infrastruture resources>"
	cd terraform && terraform init 
	chmod +x ./scripts/upload_state.sh
	chmod +x ./scripts/terraform_migrate.sh
	./scripts/upload_state.sh 
	./scripts/terraform_migrate.sh

tf-mgt:
	@echo "Migrating Terraform <Migrate infrastructure resources>"
	chmod +x ./scripts/terraform_migrate.sh
	./scripts/terraform_migrate.sh

tf-refresh:
	@echo "Refreshing Terraform <Refresh infrastruture resources>"
	cd terraform && terraform refresh

tf-st-list:
	@echo "List Terraform state <List infrastruture resources>"
	cd terraform && terraform state list

json-fmt:
	@echo "Formating JSON <Auto-format JSON code>"
	jq . .aws/task-definition.json > temp.json && mv temp.json .aws/task-definition.json
	jq . .aws/task-definition-actions.json > temp.json && mv temp.json .aws/task-definition-actions.json

aws-user:
	@echo "Check current AWS user signed in to AWS CLI"
	aws sts get-caller-identity

aws-region:
	@echo "Check current AWS region"
	aws configure get region

qdrant-create:
	@echo "Create Qdrant collection"
	poetry run python src/cli/qdrant_cli.py create

qdrant-delete:
	@echo "Delete Qdrant collection"
	poetry run python src/cli/qdrant_cli.py delete

qdrant-info:
	@echo "Info Qdrant collection"
	poetry run python src/cli/qdrant_cli.py info

upload_secrets:
	@echo "Uploading secret to AWS Secret Manager"
	chmod +x ./scripts/upload_secrets.sh
	./scripts/upload_secrets.sh

zip-lambda:
	@echo "Zipping Lambda function"
	cd lambda &&\
	zip lambda.zip *.py

all: install format lint
