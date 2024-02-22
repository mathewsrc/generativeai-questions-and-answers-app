import boto3
import json
import logging
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores.qdrant import Qdrant
from qdrant_client import QdrantClient
from utils import Embedding, Embeddings, get_embeddings

# Constants
AWS_EMBEDDINGS = ["amazon.titan-embed-text-v1"]

# AWS S3 client
s3 = boto3.client("s3")

# Logging setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_client(url: str, api_key: str) -> QdrantClient:
    """Create and return a Qdrant client."""
    return QdrantClient(url=url, api_key=api_key)

def get_collection_info(url: str, api_key: str, collection_name: str) -> None:
    """Log the collection info."""
    client = get_client(url, api_key)
    info = client.get_collection(collection_name=collection_name)
    logger.info(json.dumps(f"Collection info\n: {info}", indent=4))

def get_documents_from_pdf(bucket_name: str, key: str) -> list:
    """Download a PDF from S3, load it, and split it into documents."""
    s3_object_name = key.split("/")[-1]

    logger.info(f"Downloading file from s3://{bucket_name}/{key}")
    logger.info(f"File name: {s3_object_name}")

    s3.download_file(bucket_name, key, f"/tmp/{s3_object_name}")

    loader = PyPDFLoader(f"/tmp/{s3_object_name}")
    documents = loader.load()

    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
    docs = text_splitter.split_documents(documents)
    logger.info(f"Number of documents after split: {len(docs)}")
    return docs

def create_vectorstore(
    url: str,
    api_key: str,
    bucket_name: str,
    object_key: str,
    collection_name: str,
    region_name: str,
    embedding_model: str,
) -> None:
    """Create a vector store from a PDF in an S3 bucket."""
    docs = get_documents_from_pdf(bucket_name=bucket_name, key=object_key)

    embeddings = get_embeddings(
        embedding=Embedding(embeddings=Embeddings.BEDROCK, model_name=embedding_model),
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
    get_collection_info(url, api_key, collection_name)