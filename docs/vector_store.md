# Qdrant Vector Store with Lambda and S3

This project uses Lambda Function and s3 as a trigger to create a vector store in a Qdrant cluster
You can find the documents in the `documents/` directory.

The Lambda Function uses a Docker image stored in ECR. Below you can find the details of the image
used by Lambda:

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


The `creator_vectorstore(...)` function call the get_documents_from_pdf function which download the PDF file uploaded
to S3 into the Lambda `/tmp` directory, which is the only place where we have permission to write files, and convert it into a set of smaller documents also called chunks, convert it into a vector representation also called embedding, and uploaded it to Qdrant Cloud using Langchain. 

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
