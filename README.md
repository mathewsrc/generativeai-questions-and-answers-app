[![CI](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml/badge.svg)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml)
[![Terraform](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/terraform.yml/badge.svg)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/terraform.yml)
[![Deploy (Amazon ECS)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/aws.yml/badge.svg)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/aws.yml)

# GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI
Question and Answer application using Amazon Bedrock, Langchain, and FastAPI


1. Load PDF documents
2. Chunk documents
3. Embedding documents and store them in the Vector Store
4. Build a retrieval-augmented generation pipeline for querying data
5. Build a question answer that answers questions about the documents


## Requirements
- [Python](https://www.python.org/downloads/)
- [Poetry](https://python-poetry.org/docs/#installation)
- [Docker](https://docs.docker.com/desktop/install/windows-install/)
- [AWS Account](https://aws.amazon.com/resources/create-account/)
- [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)
- [Terraform API token](tutorials/terraform.md)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Qdrant](https://cloud.qdrant.io/login)

## How to run this application

1. Install pipx (in GitHub Codespaces jump to `Install Poetry` as it already has pipx installed)

Linux
```bash
sudo apt update
sudo apt install pipx
pipx ensurepath
```

Windows
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install pipx
pipx ensurepath
```
Now open a new terminal to use pipx

2. Install Poetry

```bash
# Install Poetry
pipx install --force poetry

# Enable tab completion for Bash
poetry completions bash >> ~/.bash_completion

# Init Poetry
poetry init

# Install Poetry dependencies
poetry install

# Check Poetry version
poetry --version
```

3. Install Terraform (Linux). For more information see [Terraform](https://developer.hashicorp.com/terraform/install#Linux)

```bash
# Install Terraform by HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the official HashiCorp Linux repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt update && sudo apt install terraform

# Verify the installation
terraform --version
```

Alternatively, run the Bash script `install_terraform.sh` in the terminal. 

4. Enable Bedrock Foundation Models

Then, navigate to the AWS console, access Amazon Bedrock, and go to Template Access. Enable the base templates that you wish to utilize. I created a [bedrock_tutorial](tutorials/bedrock_tutorial.md) tutorial for you on how to request model access.

5. Install AWS CLI

Finally, we need to install AWS CLI to use Terraform with AWS provider. Refer to the [cliv2-linux-install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#cliv2-linux-install) for more information:

To install the AWS CLI, execute the following commands in the terminal:

```bash
# Install the AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the AWS CLI
unzip awscliv2.zip

# Install the AWS CLI
sudo ./aws/install

# Clean up the files
rm -rf awscliv2.zip aws

# Verify the AWS CLI
aws --version

# Configure the AWS CLI
aws configure
```

Alternatively, you can run the provided Bash script `install_aws_cli.sh` in the terminal to streamline the installation process.

### Configure AWS CLI

We have two alternatives for setting up the AWS Command Line Interface (CLI):

- Configure as an Administrator (less secure): This option provides broad permissions but is less secure as it grants extensive access.
- Create a new user with restricted permissions: For enhanced security, this alternative involves creating a new user with limited permissions.

For this project, a new user has been created in AWS Identity and Access Management (IAM), and policies 
with minimal permissions have been defined. You can review the necessary policies in [policies](tutorials/iam_user_policies.md).

Finally, in the terminal, execute the command `aws configure` and provide the Access Key and Secret Access Key that were just created. 
Set the default region as well.

To verify your credentials, you can use one of the following commands in the terminal:

```bash
aws sts get-caller-identity
make aws-user
```

This command will retrieve details about the user, including user ID and account ID.

```
{
    "UserId": "##############",
    "Account": "############",
    "Arn": "arn:aws:iam::###########:user/##########"
}
```

## Setup Qdrant Cloud

To access Qdrant Cloud via the Client SDK, you need to create a cluster in Qdrant Cloud and obtain a Token and the cluster URL.

1. Follow the instructions on how to set up a free cluster by visiting the following link: [Qdrant-cluster](https://qdrant.tech/documentation/cloud/quickstart-cloud/)

2. Create a new file to store sensitive data

```bash
touch .env
```

3. Store the Qdrant token and cluster URL by executing the following commands:
   
QDRANT_URL = "YOUR CLUSTER URL"
QDRANT_API_KEY = "YOUR TOKEN"

### To create a collection in Qdrant Cloud using the Command-Line Interface (CLI), follow these steps:

1. Create a collection

First, open your terminal and select one of the methods below. Then specify a collection name, and choose an embedding model (this process typically takes 10-15 minutes):

```bash
make qdrant-create
poetry run python src/cli/qdrant_cli.py create
```

### Qdrant cluster

![image](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/18216ebe-a6e7-4c82-9baf-da20f633c8d9)

2. (Optional) Run the app locally for testing

```bash
make run-app
```
Next, navigate to http://127.0.0.1:8000 or http://127.0.0.1:8000/docs in your web browser.

(Optional) Docker
```bash
make docker-build
make docker-run
```

## Deploy

This project offers two deployment options: manual execution in the terminal and CI/CD with GitHub Actions.

As the Terraform backend is configured to utilize a Terraform state file stored in AWS S3, the initial step is to upload the state file to S3.

1. Execute the following command to initialize Terraform

```bash
make tf-init
```

2. In the terminal, execute the following command to upload the state file to AWS S3:

```bash
make tf-upload
```

3. Deploying using Terminal and GitHub Actions

### Manually deploy using the terminal

Follow the steps below to create the AWS infrastructure:

```bash
make tf-plan 
make tf-apply
```

These commands will invoke Terraform to configure all the necessary infrastructure.

Now, to deploy the application to ECS use the make command:

```bash
make aws-deploy
```

### Automatically deploy using GitHub actions for Continuous Integration and Continuous Deployment (CI/CD)

If you want to deploy this application to AWS ECS using GitHub actions you will need to follow some more steps:

1. CGenerate a Terraform API Token and a secret key in GitHub. Refer to the [Terraform API token](tutorials/terraform.md) inside this project
2. Set up secret keys by providing your AWS credentials. Check out the  [Github Actions Secret Keys](tutorials/aws_secret_keys.md)
3. Congratulations! You are now ready to deploy this application using CI/CD

## Tools used in this project

### Terraform

Terraform is an open-source Infrastructure as Code (IaC) tool, crafted for provisioning and managing cloud resources.

Key benefits:

- Declarative approach
- Enable collaboration, versioning, and integration into CI/CD pipelines
- Reusable modules 
- Multi-Cloud deployment
- Automation and standardization

### Amazon ECS (Elastic Container Service)

Amazon ECS (Elastic Container Service) is a fully managed container orchestration service facilitating the effortless deployment and scaling of containerized applications on AWS.

Key benefits:

- Simplified Operation: Eliminate the need to install or manage your container orchestration
- Auto-Scaling Configuration: Easily configure auto-scaling to match application demands.
- Multiple instance types, including EC2 and Fargate, to meet specific application requirements.

### Amazon ECR (Elastic Container Register)

Amazon ECR is a managed container registry service designed for storing Docker images, supporting both public and private repositories.

Key benefits:

- Image Scanning for vulnerabilities within your container images 
- Effectively manage image lifecycles with customizable policies
- Cross-Region and Cross-Account Replication: Facilitate seamless replication of images across regions and accounts for enhanced accessibility and redundancy.

### GitHub Actions

GitHub Actions is a versatile CI/CD platform facilitating build, testing, and deployment pipelines. Key advantages include:

Key benefits:

- Support for automatic, manual, scheduled, and event-triggered workflows
- Compatibility with Linux, Windows, and macOS virtual machines for running workflows
- Intuitive visual workflow for efficient debugging and error resolution
- Seamless integration with AWS ECS and Terraform

### Docker

Docker is a platform that uses OS-level virtualization to deliver software in packages called containers. We can use Docker to create microservices applications using FastAPI and run them locally or on cloud services as ECS.

Key benefits:

- Isolation
- Easy setup using Dockerfile
- Portability (run on on-premises servers and in the cloud)

### Qdrant

Qdrant Cloud offers managed Qdrant instances on the cloud, serving as a powerful similarity search engine.

Key benefits:

- Seamless Integration with LangChain
- Software-as-a-Service (SaaS) 
- Easily scalability 
- Comprehensive Monitoring and Logging for Cluster Performance
- Availability on Major Cloud Platforms: AWS, GCP, and Azure

## Costs 

https://aws.amazon.com/bedrock/pricing/

https://aws.amazon.com/fargate/pricing/

https://aws.amazon.com/ecr/pricing/

https://aws.amazon.com/s3/pricing/

https://aws.amazon.com/opensearch-service/pricing/
