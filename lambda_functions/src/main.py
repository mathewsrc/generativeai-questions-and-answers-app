import json
import os
from dotenv import load_dotenv
from create_vector_store import create_vectorstore

# Load environment variables
load_dotenv()

EMBEDDING_MODEL = "amazon.titan-embed-text-v1"
COLLECTION_NAME = "cnu"

# Environment variables
QDRANT_URL = os.getenv("QDRANT_URL_AWS")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY_AWS")
BUCKET_NAME = os.getenv("BUCKET_NAME")
AWS_REGION = os.getenv("REGION")

def lambda_handler(event, context):
    """AWS Lambda function handler."""
    # Extract bucket name and object key from event
    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]

    # Create vector store
    create_vectorstore(
        url=QDRANT_URL,
        api_key=QDRANT_API_KEY,
        bucket_name=bucket_name,
        region_name=AWS_REGION,
        object_key=object_key,
        collection_name=COLLECTION_NAME,
        embedding_model=EMBEDDING_MODEL,
    )

    return {"statusCode": 200, "body": json.dumps("Successful!")}