from langchain_community.vectorstores.qdrant import Qdrant
from langchain_community.document_loaders import S3FileLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from qdrant_client import QdrantClient
import json

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


def info(url: str, api_key: str, collection_name: str) -> None:
	try:
		client = get_client(url, api_key)
		info = client.get_collection(collection_name=collection_name)
		print(json.dumps(f"Collection info\n: {info}", indent=4))
	except Exception as e:
		print(f"Error: {e}")


def get_documents_from_pdf(
	bucket_name: str, key: str, collection_name: str, region_name: str
) -> list:
	loader = S3FileLoader(bucket=bucket_name, key=key, region_name=region_name)
	documents = loader.load()

	# Split documents
	text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
	docs = text_splitter.split_documents(documents)
	print(f"Number of documents after split: {len(docs)}")
	return docs


def get_client(url: str, api_key: str) -> QdrantClient:
	return QdrantClient(url=url, api_key=api_key)


def create_vectostore(
	url: str,
	api_key: str,
	bucket_name: str,
	object_key: str,
	collection_name: str,
	region_name: str,
	embedding_model: str,
) -> None:
	try:
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
		print("Creating collection...")

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
	except Exception as e:
		print(f"Error: {e}")
