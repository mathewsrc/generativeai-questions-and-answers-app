import json
from create_vector_store import create_vectostore
import os
from dotenv import load_dotenv

load_dotenv()

EMBEDDING_MODEL = "amazon.titan-embed-text-v1"
COLLECTION_NAME = "cnu"

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
BUCKET_NAME = os.environ.get("BUCKET_NAME")
AWS_REGION = os.environ.get("REGION")


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
