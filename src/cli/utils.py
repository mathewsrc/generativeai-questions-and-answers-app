from enum import Enum
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
import click
from langchain_community.embeddings.huggingface import HuggingFaceEmbeddings
from langchain_community.embeddings import BedrockEmbeddings
from global_variables import AWS_REGION
import boto3
from dataclasses import dataclass
from dotenv import load_dotenv
import os
from qdrant_client import QdrantClient

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")

boto_session = boto3.Session(region_name=AWS_REGION)
credentials = boto_session.get_credentials()

# bedrock
bedrock_models = boto3.client("bedrock", region_name=AWS_REGION)
bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_REGION)


class Embeddings(Enum):
	HUGGINGFACE = "HuggingFaceEmbeddings"
	BEDROCK = "BedrockEmbeddings"


@dataclass()
class Embedding:
	embeddings: Embeddings
	model_name: str


huggingface_embeddings = [
	"BAAI/bge-small-en",
	"sentence-transformers/all-MiniLM-L6-v2",
	"sentence-transformers/all-mpnet-base-v2",
	"sentence-transformers/all-distilroberta-v1",
]

huggingface_llm = [
	"meta-llama/Llama-2-7b-chat-hf",
	"microsoft/phi-2",  # 5G
	"TinyLlama/TinyLlama-1.1B-Chat-v1.0",  # 2.2G
]

aws_embeddings = ["amazon.titan-embed-text-v1"]

aws_llm = ["anthropic.claude-v2"]


def get_huggingface_embeddings(model_name: str) -> HuggingFaceEmbeddings:
	model_kwargs = {"device": "cpu"}
	encode_kwargs = {"normalize_embeddings": False}
	embeddings = HuggingFaceEmbeddings(
		model_name=model_name, model_kwargs=model_kwargs, encode_kwargs=encode_kwargs
	)
	click.echo(click.style("Embedding finished!", fg="green"))
	return embeddings


def get_bedrock_embeddings(model_name: str) -> BedrockEmbeddings:
	embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_name)
	click.echo(click.style("Embedding finished!", fg="green"))
	return embeddings


def get_embeddings(embedding: Embedding):
	click.echo(click.style(f"Embedding model: {embedding.model_name}", fg="green"))
	click.echo(click.style(f"Embedding type: {embedding.embeddings}", fg="green"))
	if embedding.embeddings == Embeddings.HUGGINGFACE:
		return get_huggingface_embeddings(embedding.model_name)
	elif embedding.embeddings == Embeddings.BEDROCK:
		return get_bedrock_embeddings(embedding.model_name)
	else:
		raise Exception("Invalid embedding type")


def get_documents_from_pdf(collection_name: str) -> list:
	# Load documents
	loader = PyPDFDirectoryLoader(f"./documents/{collection_name}")
	documents = loader.load()

	# Split documents
	text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
	docs = text_splitter.split_documents(documents)
	click.echo(click.style(f"Number of documents after split: {len(docs)}", fg="green"))
	return docs


def get_client(url: str, api_key: str) -> QdrantClient:
	return QdrantClient(url=url, api_key=api_key)


def get_prompt() -> str:
	return """
                Use the following pieces of context to provide a concise answer to the question at the end. 
                If you don't know the answer, just say that you don't know, don't try to make up an answer.
                                
                Question: {question}
                                
                {context}

                Answer:
            """
