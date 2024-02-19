from langchain_community.vectorstores.qdrant import Qdrant
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from qdrant_client import QdrantClient
import json
import logging
import boto3

from utils import (
	get_embeddings,
	Embedding,
	Embeddings,
)

huggingface_embeddings = [
	"BAAI/bge-small-en",
	"sentence-transformers/all-MiniLM-L6-v2",
	"sentence-transformers/all-mpnet-base-v2",
	"sentence-transformers/all-distilroberta-v1",
]

aws_embeddings = ["amazon.titan-embed-text-v1"]

s3 = boto3.client("s3")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def info(url: str, api_key: str, collection_name: str) -> None:
	client = get_client(url, api_key)
	info = client.get_collection(collection_name=collection_name)
	logger.info(json.dumps(f"Collection info\n: {info}", indent=4))


def get_documents_from_pdf(
	bucket_name: str, key: str, collection_name: str, region_name: str
) -> list:
	
	s3_object_name = key.split("/")[-1]

	logger.info(f"Downloading file from s3://{bucket_name}/{key}")
	logger.info(f"File name: {s3_object_name}")
 
	s3.download_file(bucket_name, key, f"/tmp/{s3_object_name}")
 
	loader = PyPDFLoader(f"/tmp/{s3_object_name}")
	documents = loader.load()

	# Split documents
	text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
	docs = text_splitter.split_documents(documents)
	logger.info(f"Number of documents after split: {len(docs)}")
	return docs


def get_client(url: str, api_key: str) -> QdrantClient:
	return QdrantClient(url=url, api_key=api_key)


def create_vectorstore(
	url: str,
	api_key: str,
	bucket_name: str,
	object_key: str,
	collection_name: str,
	region_name: str,
	embedding_model: str,
) -> None:
	docs = get_documents_from_pdf(
		bucket_name=bucket_name,
		key=object_key,
		collection_name=collection_name,
		region_name=region_name,
	)

	if embedding_model in huggingface_embeddings:
		embedding = Embeddings.HUGGINGFACE
		model_name = embedding_model

	elif embedding_model in aws_embeddings:
		embedding = Embeddings.BEDROCK
		model_name = embedding_model

	else:
		raise ValueError("Invalid embedding model name")

	embeddings = get_embeddings(
		embedding=Embedding(embeddings=embedding, model_name=model_name),
		region_name=region_name,
	)
	logger.info("Creating collection...")

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
	info(url, api_key, collection_name)
	
