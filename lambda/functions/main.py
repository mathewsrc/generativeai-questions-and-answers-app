import json
from create_vector_store import create_vectostore
import os
from dotenv import load_dotenv

load_dotenv()

EMBEDDING_MODEL = "amazon.titan-embed-text-v1"
COLLECTION_NAME = "cnu"
AWS_REGION = "us-east-1"
BUCKET_NAME = "bedrock-question-answer"

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")

def lambda_handler(event, context):
	try:
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
	except Exception as e:
		print(f"Error: {e}")
		return {"statusCode": 500, "body": json.dumps(f"Error: {e}")}