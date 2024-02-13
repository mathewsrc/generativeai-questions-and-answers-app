# Qdrant Vector Store with Lambda and S3

This project utilizes a Lambda Function with S3 as a trigger to generate a vector store within a 
Qdrant cluster. The documents are located in the `documents/` directory.

<p align="center">
<img src="https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/731b8ac3-b771-4513-99cd-a7db7f6725a6" width=80%>
<p/>

## Permissions required

You can find the permissions required to create the following resources in the `iam_user_policies.md` document
in this directory.

## Docker Image

The Lambda Function relies on a Docker image stored in ECR. Here are the details of the image 
employed by Lambda:

```docker
FROM public.ecr.aws/lambda/python:3.12

# Install dependencies
RUN pip3 install \ 
     --no-cache-dir \
     --platform manylinux2014_x86_64 \
     --target "${LAMBDA_TASK_ROOT}" \
     --implementation cp \
     --python-version 3.12 \ 
     --only-binary=:all: --upgrade boto3 \
          langchain \
          langchain-community \
          qdrant-client \
          python-dotenv \
          pypdf

# Copy function code
COPY ./lambda/src/main.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/utils.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/create_vector_store.py  ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "main.lambda_handler" ]
```

This Docker image uses a base image provided by AWS which comes with `python 3.12` as runtime. 
The dependencies are installed into a directory provided by the base image as well the Python code
required. The CMD is set to call the `main.py` module and its entrypoint function `lambda_handle(event, context)`.
The `lambda_handler(event, context)` function call the `create_vectorstore(...)` from `create_vector_store` module.

```python
import json
from create_vector_store import create_vectostore
import os
from dotenv import load_dotenv
import os

load_dotenv()

EMBEDDING_MODEL = "amazon.titan-embed-text-v1"
COLLECTION_NAME = "cnu"

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
BUCKET_NAME = os.environ.get("BUCKET_NAME")
AWS_REGION = os.environ.get("AWS_REGION")


def lambda_handler(event, context):
	bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
	object_key = event["Records"][0]["s3"]["object"]["key"]

	create_vectostore(
		url=QDRANT_URL,
		api_key=QDRANT_API_KEY,
		bucket_name=bucket_name,
		region_name=AWS_REGION,
		object_key=object_key,
		collection_name=COLLECTION_NAME,
		embedding_model=EMBEDDING_MODEL,
	)
	return {"statusCode": 200, "body": json.dumps("Succesfull!")}
```



The `create_vectorstore(...)` function initiates the get_documents_from_pdf function, which, in turn, downloads the uploaded PDF file from S3 to the Lambda `/tmp` directory—the exclusive location with write permissions. Subsequently, it divides the document into smaller sections, referred to as chunks, converts these chunks into a vector representation, also known as embedding, and uploads the resulting data to Qdrant Cloud via Langchain.

```python

def create_vectorstore(...) -> None:

    get_documents_from_pdf(...)

    ...

    embeddings = get_embeddings(...)

	vectorstore = Qdrant.from_documents(
		documents=docs,
		embedding=embeddings,
		url=url,
		prefer_grpc=True,
		api_key=api_key,
		collection_name=collection_name,
		force_recreate=False,
	)

def get_documents_from_pdf(
	bucket_name: str, key: str, collection_name: str, region_name: str
) -> list:
	
	...

	s3.download_file(bucket_name, key, f"/tmp/{s3_object_name}")
 
	loader = PyPDFLoader(f"/tmp/{s3_object_name}")
	documents = loader.load()

	# Split documents
	text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
	docs = text_splitter.split_documents(documents)
	logger.info(f"Number of documents after split: {len(docs)}")
	return docs
```

## Lambda Function Policy

The Lambda Function requires permission to interact with other services. These include permissions
to access CloudWatch for monitoring, S3 for downloading PDF files, and Bedrock for invoking the 
Amazon `amazon.titan-embed-text-v1` model for embedding documents.

**Terraform Policy Document**

```terraform
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.name}:*:*"]
  }

  statement {
    sid = "S3Access"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    sid       = "BedrockAccess"
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", "bedrock:ListFoundationModels"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
}
```
