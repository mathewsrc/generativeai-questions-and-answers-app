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

3. Install Terraform (Linux). More information see [Terraform](https://developer.hashicorp.com/terraform/install#Linux)

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

Alternatively, run the provided Bash script `install_terraform.sh` in the terminal. 


4. Enable Bedrock Foundation Models

Then go to the AWS console > Amazon Bedrock > Template Access and enable the base templates you want to use. I created a [bedrock_tutorial](tutorials/bedrock_tutorial.md) tutorial for you on how to request model access.

5. Install AWS CLI

Finally, we need to install AWS CLI to use Terraform with aws provider. See [link](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#cliv2-linux-install) for more information:

Execute the following code to install AWS CLI: 

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

Alternatively, run the provided Bash script `install_aws_cli.sh` in the terminal. 

6. Configure AWS CLI

We currently have two alternatives for setting up the AWS Command Line Interface (CLI):

- Configure as an Administrator (less secure)
- Create a new user with restricted permissions.

For this project, I opted to create a new user in AWS Identity and Access Management (IAM) and define policies with minimal permissions. You can check the policies needed in [policies](tutorials/iam_user_policies.md).

Finally we can use the command `aws configure` in the terminal and pass the Access Key and the Secret access key that we just created. You can set the default region too.

You can check your credentials using one of the following command in the Terminal
```bash
aws sts get-caller-identity

make aws-user
```

This command will return details about the user such as user id and account id.
```
{
    "UserId": "##############",
    "Account": "############",
    "Arn": "arn:aws:iam::###########:user/##########"
}
```

## Deploy

This project has two deployment options: manually in the Terminal and CI/CD with GitHub Actions

As Terraform backend if configured to use a Terraform state file located in AWS S3 we need first to 
upload the state file to S3.

1. In the terminal init Terraform

```bash
make tf-init
```

2. Again in the terminal execute the following script

```bash
scripts/upload_state.sh
```

### Terminal

You can deploy this application by following the steps below:

```bash
make tf-plan 
make tf-apply or make tf-deploy
```

These commands will called Terraform to provide all infrastructure required.

Now we can deploy the application using a bash script:

```bash
scripts/deploy.sh
```

If you want to deploy this application to AWS ECS using GitHub actions you will need to follow some more steps:

1. Create a Terraform API Token and a secret key in GitHub. See [Terraform API token](tutorials/terraform.md) inside this project
2. Create secret keys passing your AWS credentials. See [Github Actions Secret Keys](tutorials/aws_secret_keys.md)
3. Well done! Now you can deploy this application using CI/CD

Now we have everything setup and you can how this application.

## Tools used in this project

### Terraform

Terraform is an open-source infrastructure as a code tool designed for provisioning and managing cloud resources in the cloud known as Infrastructure as Code (IaC).

Benefits of IaC:
- IaC is a declarative which means that we can specify the desired state of infrastructure
- It can be managed as source code, we can commit, collaborate, and easily use it inside our CI/CD pipeline
- IaC is portable, we can build reusable modules across an organization
- Can be used for multi-cloud deployments
- Can automate changes and standardize configurations

### Amazon ECS (Elastic Container Service)

Amazon ECS (Elastic Container Service) is a fully managed container orchestration service that allows you to run and scale containerized applications on AWS easily. 

Benefits of ECS:
- No need to install or operate your container orchestration
- Easily auto-scaling configuration
- Different types of instances such as EC2 and Fargate

### Amazon ECR (Elastic Container Register)

Amazon ECR is a managed container register service to store Docker images that supports public and private repositories

Benefits of ECR:
- Image scanning helps in identifying software vulnerabilities in your container images
- Lifecycle policies for managing the lifecycle of the images
- Cross-Region and cross-account replication 

### Amazon OpenSearch Service

Open Search can search semantically similar or semantically related items and it can be used for recommendation engines, search engines, chatbots, and text classification. First, PDFs (or any kind of data such as videos, audio, and images) are converted into embedding representation, second, the embeddings are uploaded to OpenSearch or any other Vector Store. Then we can create an index to run queries to get recommendations or results. The serveless version of Open Search is an OpenSearch cluster that scales compute capacity based on your application's needs.

Benefits:
- Pay only for what you use
- Auto-scaling configuration
- High-performing vector search

### GitHub Actions

GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform for build, test, and deploy pipelines.

Benefits:
- Automatic, manual, schedule and event triggered workflow support 
- Linux, Windows, and macOS virtual machines to run workflows
- Visual workflow for debug and error fix
- Can easily be used with AWS ECS and Terraform

### Docker

Docker is a platform that use OS-level virtualization to deliver software in packages called containers.
We can use Docker to create microservices applications using FastAPI and run it locally or on cloud services as ECS.

Benefits:
- Isolation
- Easy setup using Dockerfile
- Portability (run on on-premises servers and in the cloud)


## Costs 

https://aws.amazon.com/bedrock/pricing/

https://aws.amazon.com/fargate/pricing/

https://aws.amazon.com/ecr/pricing/

https://aws.amazon.com/s3/pricing/

https://aws.amazon.com/opensearch-service/pricing/
