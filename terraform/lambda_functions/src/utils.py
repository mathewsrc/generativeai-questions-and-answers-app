from enum import Enum
from langchain_community.embeddings import BedrockEmbeddings
import boto3
from dataclasses import dataclass
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class Embeddings(Enum):
	BEDROCK = "BedrockEmbeddings"


@dataclass()
class Embedding:
	embeddings: Embeddings
	model_name: str


def get_bedrock_embeddings(model_name: str, region_name: str) -> BedrockEmbeddings:
	bedrock_runtime = boto3.client("bedrock-runtime", region_name=region_name)
	embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_name)
	logger.info("Embedding finished!")
	return embeddings


def get_embeddings(embedding: Embedding, region_name: str):
	logger.info(f"Embedding model: {embedding.model_name}")
	logger.info(f"Embedding type: {embedding.embeddings}")
	if embedding.embeddings == Embeddings.BEDROCK:
		return get_bedrock_embeddings(embedding.model_name, region_name=region_name)
	else:
		raise Exception("Invalid embedding type")
