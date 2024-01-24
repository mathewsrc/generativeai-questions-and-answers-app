from langchain_community.vectorstores.qdrant import Qdrant
import click
import boto3
import os
from dotenv import load_dotenv
import sys

module_path = ".."
sys.path.append(os.path.abspath(module_path))
from global_variables import COLLECTION_NAME, AWS_REGION, AWS_S3_BUCKET, DOCUMENTS_PATH
from utils import (
	get_embeddings,
	get_documents_from_pdf,
	get_client,
	Embedding,
	Embeddings,
	huggingface_embeddings,
	aws_embeddings,
)

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")

boto_session = boto3.Session(region_name=AWS_REGION)


@click.group()
def cli():
	pass


@cli.command("download-docs")
@click.option("--collection-name", required=True, prompt=True, help="Collection name")
@click.option("--bucket", help="S3 bucket")
def download_files(collection_name, bucket=None):
	s3 = boto3.resource("s3")
	if bucket is None:
		bucket = AWS_S3_BUCKET
	bucket = s3.Bucket(bucket)
	for obj in bucket.objects.all():
		key = obj.key
		if key.endswith(".pdf"):
			bucket.download_file(key, f"{DOCUMENTS_PATH}/{collection_name}/{key}")
			click.echo(click.style(f"Downloaded {key}", fg="green"))


@cli.command("create")
@click.option("--url", default=QDRANT_URL, help="Qdrant server URL")
@click.option("--api-key", default=QDRANT_API_KEY, help="Qdrant API key")
@click.option("--collection-name", required=True, prompt=True, help="Qdrant collection name")
@click.option(
	"--embedding-model",
	required=True,
	prompt=True,
	type=click.Choice(huggingface_embeddings + aws_embeddings),
	help="Embedding model name",
)
def create_vectostore(url, api_key, collection_name, embedding_model):
	try:
		docs = get_documents_from_pdf(collection_name)

		if embedding_model in huggingface_embeddings:
			embedding = Embeddings.HUGGINGFACE
			model_name = embedding_model

		elif embedding_model in aws_embeddings:
			embedding = Embeddings.BEDROCK
			model_name = embedding_model

		else:
			raise ValueError("Invalid embedding model name")

		embeddings = get_embeddings(
			embedding=Embedding(embeddings=embedding, model_name=model_name)
		)
		click.echo(click.style("Creating collection... (15-35 minutes)", fg="green"))

		vectorstore = Qdrant.from_documents(
			documents=docs,
			embedding=embeddings,
			url=url,
			prefer_grpc=True,
			api_key=api_key,
			collection_name=collection_name,
			force_recreate=False,
		)
		vectorstore.client.close()
		click.echo(click.style("Collection created!", fg="green"))
	except Exception as e:
		click.echo(click.style(f"Error: {e}", fg="red"))
		return
	return vectorstore


@cli.command("delete")
@click.option("--url", default=QDRANT_URL, help="Qdrant server URL")
@click.option("--api-key", default=QDRANT_API_KEY, help="Qdrant API key")
@click.option("--collection-name", default=COLLECTION_NAME, help="Qdrant collection name")
def delete_collection(url, api_key, collection_name):
	client = get_client(url, api_key)
	client.delete_collection(collection_name=collection_name)
	click.echo(click.style("Collection deleted!", fg="green"))


@cli.command("info")
@click.option("--url", default=QDRANT_URL, help="Qdrant server URL")
@click.option("--api-key", default=QDRANT_API_KEY, help="Qdrant API key")
@click.option("--collection-name", required=True, prompt=True, help="Qdrant collection name")
def info(url, api_key, collection_name):
	try:
		client = get_client(url, api_key)
		info = client.get_collection(collection_name=collection_name)
		click.echo(click.style(f"Collection info: {info}", fg="green"))
	except Exception as e:
		click.echo(click.style(f"Error: {e}", fg="red"))


if __name__ == "__main__":
	cli()
