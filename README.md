[![CI](https://github.com/mathewsrc/generativeai-questions-and-answers-app/actions/workflows/ci.yml/badge.svg)](https://github.com/mathewsrc/generativeai-questions-and-answers-app/actions/workflows/ci.yml)
[![Deploy](https://github.com/mathewsrc/generativeai-questions-and-answers-app/actions/workflows/cd.yml/badge.svg)](https://github.com/mathewsrc/generativeai-questions-and-answers-app/actions/workflows/cd.yml)

# Generative AI: Questions and Answers app for competition notices
Question and Answer application for competition notices using Amazon Bedrock, Langchain, Qdrant, AWS ECS, and FastAPI

## Objective

Many people end up giving up reading competition notices due to different factors such as too much information, inaccessible font size, and difficulty in interpretation. This project aims to build a generative AI application to help candidates quickly and easily understand competition notices.

PT-BR

Muitas pessoas acabam por desistir de ler editais de concursos devidos a diferentes fatores como: muitas informações, tamanho de letras não acessíveis e dificuldade de interpretação. Este projeto tem como objetivo construir uma aplicação de IA generativa para auxiliar candidados a compreender de forma facil e rápida editais de concursos.

## Overview

![Generative AI - RAG](https://github.com/mathewsrc/generativeai-questions-and-answers-app/assets/94936606/e5ea6499-e52e-4a44-a478-78355dd4839a)

## Step by step

1. Upload the Terraform state file to AWS S3.
2. Push the code and Terraform scripts to GitHub.
3. Trigger GitHub Actions.
4. Use GitHub Actions to leverage Terraform for creating S3 and Lambda Function infrastructure, and for uploading documents.
5. Trigger the Lambda Function via S3 to process documents.
6. Utilize a container image stored in ECR within the Lambda Function. This image contains all the necessary code to convert PDFs to embeddings using Langchain and the AWS Bedrock embeddings model.
7. Upload the embeddings to Qdrant Cloud using the Python API client.
8. Use GitHub Actions and AWS CLI to upload the Qdrant URL and API key to AWS Secrets Manager.
9. Use GitHub Actions and Terraform to create an ECR repository and all other required resources such as AWS network (VPC, Subnets, Internet gateway, NAT gateway, Routes, security groups, etc), AWS CloudWatcher, Elastic Load Balancer, API Gateway, and VPC link. Log in to ECR and use AWS aws-actions to build, tag, and push the Docker image to ECR.
10. Pull the Docker image from ECR using ECS.
11. Make a call to the AWS API Gateway from the user's end.
12. Route the request from the AWS API Gateway to the VPC link, enabling communication between the API Gateway and the Amazon ECS service within the Amazon VPC.
13. Redirect traffic via the Elastic Load Balancer to the least used node, ensuring a balanced load across each container running the same service.
14. Retrieve the Qdrant Cloud credentials from the AWS Secrets Manager using the ECS service.
15. Access Qdrant Cloud using its API to get the document collection via the ECS Service.
16. Integrate the AWS Bedrock Foundation Model and the embeddings from Qdrant Cloud using Langchain.
17. Generate an answer about the documents for the user using the embeddings from Qdrant Cloud via the LLM.

# Here is more details about this project

[Setup Bedrock](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/bedrock_tutorial.md)

[Setup GitHub Actions secrets](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/github_actions_secret_keys.md)

[Setup Terraform Cloud](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/terraform.md)

[AWS network details](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/network.md)

[How to create a vector store with Lambda, s3, Bedrock and Qdrant Cloud](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/vector_store.md)

[Microservice with ECS details](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/microservice.md)

[How to upload the Terraform state file and PDFs](https://github.com/mathewsrc/generativeai-questions-and-answers-app/blob/main/docs/s3.md)


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

Then, navigate to the AWS console, access Amazon Bedrock, and go to Template Access. Enable the base templates that you wish to utilize. I created a [bedrock_tutorial](docs/bedrock_tutorial.md) tutorial for you on how to request model access.

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
```

Alternatively, you can run the provided Bash script `install_aws_cli.sh` in the terminal to streamline the installation process.

### Configure AWS CLI

In the terminal run the following command:

```bash
# Configure the AWS CLI
aws configure
```

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

1. Follow the instructions on how to set up a free cluster by visiting the following link:

https://qdrant.tech/documentation/cloud/quickstart-cloud/

3. Export the Qdrant token and cluster URL
   
Use the following command in the terminal to export secrets:

```bash
export QDRANT_URL="<YOUR QDRANT CLOUD URL>"
export QDRANT_API_KEY="<YOUR API KEY>"
```

### Qdrant cluster

![image](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/18216ebe-a6e7-4c82-9baf-da20f633c8d9)

2. (Optional) Run the app locally for testing

```bash
make run-app
```
Next, navigate to http://127.0.0.1:8000 or http://127.0.0.1:8000/docs in your web browser.


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

1. First update the AWS region in the `src/app/mai.py` file if you are using another region

Directory: `src/app/main/py`

```python
AWS_DEFAULT_REGION = "us-east-1"  # Set this to your preferred AWS region, e.g. us-west-1
```

2. Use the following command in the terminal to create all AWS resources using
Terraform. This command will invoke Terraform to configure all the necessary infrastructure.

```bash
make tf-apply
```

3. Deploy the application to ECS using the make command:

```bash
make aws-deploy
```

### Automatically deploy using GitHub actions for Continuous Integration and Continuous Deployment (CI/CD)

If you want to deploy this application to AWS ECS using GitHub actions you will need to follow some more steps:

1. Generate a Terraform API Token and a secret key in GitHub. Refer to the [Terraform API token](docs/terraform.md) inside this project
2. Save secret keys in GitHub Actions by providing your AWS credentials, and Qdrant credentials. Check out the  [Github Actions Secret Keys](docs/github_actions_secret_keys.md)

3. Replace the following environment variables in `.github/workflows/ci.yml`, `.github/workflows/cd.yml`, `src/app/main.py` files if you are using a different
   AWS region 

Directory: `.github/workflows`

```yaml
env:
  AWS_REGION: us-east-1   # Set this to your preferred AWS region, e.g. us-west-1
```

Directory: `src/app/main/py`

```python
AWS_DEFAULT_REGION = "us-east-1"  # Set this to your preferred AWS region, e.g. us-west-1
```

Congratulations! You are now ready to deploy this application using CI/CD

## Tear down the AWS resources

Terraform excels in this aspect, eliminating the need for manual navigation through the console to locate each created resource. With Terraform we can just use `terraform destroy` or `make tf-destroy` in the terminal:

```bash
cd terraform && terraform destroy
```

```bash
make tf-destroy
```

## Tools used in this project

### Bedrock

Amazon Bedrock is a fully managed service that provides a selection of high-performing foundation models (FMs) from leading AI companies such as AI21 Labs, Anthropic, Cohere, Meta, Stability AI, and Amazon. It offers a single API and a wide range of capabilities for building generative AI applications with a focus on security, privacy, and responsible AI.

Key benefits

- Offers a choice of high-performing FMs from leading AI companies, allowing users to experiment with and evaluate the best models for their use case.

- Provides the ability to privately customize FMs with user data using techniques such as fine-tuning and Retrieval Augmented Generation (RAG).

- As a serverless service, Amazon Bedrock eliminates the need for users to manage any infrastructure.

- Allows for secure integration and deployment of generative AI capabilities into user applications using familiar AWS services such 
as Lambda Functions and Elastic Container Service (ECS).

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
- Auto-Scaling Configuration: Easily configure auto-scaling to match application demands
- Multiple instance types, including EC2 and Fargate, to meet specific application requirements

Fargate

- Fargate is a serverless computing engine for containers. Fargate automatically scales in and out and manages the infrastructure
- It eliminates the need to choose EC2 instances, cluster capacity, and scaling
- Fargate has native integration with AWS VPC which permits to control of connectivity

### Amazon ECR (Elastic Container Register)

Amazon ECR is a managed container registry service designed to store Docker images, supporting public and private repositories.

Key benefits:

- Image Scanning for vulnerabilities within your container images 
- Effectively manage image lifecycles with customizable policies
- Cross-Region and Cross-Account Replication: Facilitate seamless replication of images across regions and accounts for enhanced accessibility and redundancy

### API Gateway

API Gateway is a fully managed service that supports containerized and web applications. API Gateway makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale. 

API: A set of rules that allow different software entities to communicate with each other.

Gateway: A point of entry into a system. It often serves as a proxy that forwards requests to multiple services.

Key benefits:
- Supports RESTful APIs and WebSocket APIs
- Handles traffic management and throttling
- Handles authorization and access control
- Monitoring, and API version management

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

### Lambda Functions

Lambda Function is a serverless computing service that allows you to run code without provisioning or managing servers. It provides automatic scaling based on workload.

Key benefits

- Eliminates the need to provision or manage servers, allowing you to focus on writing code.

- Automatically scales your applications in response to incoming requests or events, handling any scale of traffic.

- Supports various programming languages including Python, Go, Java, and more.

- Works with serverless and container tools such as Docker CLI for building, testing, and deploying functions.

### S3
Amazon S3 is an object storage service that offers industry-leading scalability, data availability, security, and performance. It caters to customers of all sizes and industries, providing storage solutions for a wide range of use cases.

Key benefits

- Offers industry-leading scalability to store and protect any amount of data.

- Provides cost-effective storage classes to help optimize costs.

### Secrets Manager

AWS Secrets Manager is a service that helps manage, retrieve, and rotate database credentials, API keys, and other secrets throughout their lifecycles.

Key benefits

- Provides a centralized service to manage secrets, such as database credentials and API keys.

- Allows for secure and easy retrieval of secrets when needed.

- Supports automatic rotation of secrets to enhance security.

### Elastic Load Balancer

Elastic Load Balancing is a service that automatically distributes incoming traffic across multiple targets in one or more Availability Zones, ensuring high availability and fault tolerance in your applications.

Key benefits

- Automatically distributes incoming traffic across multiple targets, such as EC2 instances, containers, and IP addresses.

- Monitors the health of its registered targets and routes traffic only to the healthy ones.

- Scales as incoming traffic changes over time.

### Langchain

LangChain is a robust framework designed for developing applications powered by language models. It enables the creation of context-aware applications that can reason based on the provided context.

Key benefits

- Allows the development of applications that can connect a language model to sources of context such as prompt instructions, few-shot examples, and content to ground its response in.

- Includes Python and JavaScript libraries and integrations such as Qdrant for a myriad of components, a basic runtime for combining these components into chains and agents.


