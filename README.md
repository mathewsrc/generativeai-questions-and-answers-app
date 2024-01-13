[![CI](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml/badge.svg)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml)

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
pipx install --force poetry &&\
poetry completions bash >> ~/.bash_completion &&\
poetry shell
poetry install --no-root
```

3. Install Terraform (Linux). More information see [Terraform](https://developer.hashicorp.com/terraform/install#Linux)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify the installation
terraform --version
```

Alternatively, run the provided Bash script `install_terraform.sh` in the terminal. 


4. Enable Bedrock Foundation Models

Then go to AWS > Amazon Bedrock > Model access ([Link](https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess)) and enable the foundation models you want to use. Notice that this project is going to create resources in the'us-east-1' region so make sure that your AWS account region is the same. Observation: some models require access grants and it can take some time until you can access it. I created a follow up instruction [bedrock_tutorial]() for you on how to require models access.

5. Install AWS CLI

Finally, we need to install AWS CLI so Terraform can access your credentials. See [link](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#cliv2-linux-install) for more information:

Execute the following code to install AWS CLI: 

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Confirm installation
aws --version
```

Alternatively, run the provided Bash script `install_aws_cli.sh` in the terminal. 

6. Configure AWS CLI

We currently have two alternatives for setting up the AWS Command Line Interface (CLI):

- Configure as an Administrator (less secure)
- Create a new user with restricted permissions.

For this project, I opted to created a new user in AWS Identity and Access Management (IAM) and define policies with minimal permissions. To learn the steps for creating a new user with the necessary permissions to execute this project, please refer to the [bedrock_tutorial]()


Finally we can use the command `aws configure` in the terminal and pass the Access Key and the Secret access key that we just created.

Now we have everything setup and you can how this application.



## Costs (EUA)

Observation: values can change any time.

AWS Embeddings Titan = US$ 0,10 per 1 million tokens 

Claude V2 =  US$ 0,01 per 1000 input tokens and US$ 0,03 output tokens 


## Tools used in this project

Terraform

Terraform is an open-source infrastructure as a code tool designed for provisioning and managing cloud resources in the cloud known as Infrastructure as Code (IaC).

Benefits of IaC:
- IaC is a declarative which means that we can specify the desired state of infrastructure
- It can be managed as source code, we can commit, collaborate, and easily use it inside our CI/CD pipeline
- IaC is portable, we can build reusable modules across an organization
- Can be used for multi-cloud deployments
- Can automate changes and standardize configurations


Amazon ECS (Elastic Container Service)

Amazon ECS (Elastic Container Service) is a fully managed container orchestration service that allows you to easily run and scale containerized applications on AWS. 

Benefits of ECS:
- No need to install or operate own container orchestration
- Easily auto scaling configuration
- Different type os instances such as EC2 and Fargate
