[![CI](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml/badge.svg)](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/actions/workflows/ci.yml)

# GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI
Question and Answer application using Amazon Bedrock, Langchain, and FastAPI


1. Load PDF documents
2. Chunk documents
3. Embedding documents and store them in the Vector Store
4. Build a retrieval-augmented generation pipeline for querying data
5. Build a question answer that answers questions about the documents


## Tools used in this project

Terraform

Terraform is a tool designed for provisioning resources in the cloud known as Infrastructure as Code (IaC).
Benefits of IaC:
- IaC is a declarative which means that we can specify the desired state of infrastructure
- It can be managed as source code, we can commit, collaborate, and easily use it inside our CI/CD pipeline



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

## Costs

Embeddings = US$ 0,10 per 1 million tokens (EUA)

Claude V2 =  US$ 0,01 per 1000 input tokens and US$ 0,03 output tokens 
