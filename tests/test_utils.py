import pytest
from terraform.lambda_functions.src.utils import get_embeddings, Embedding, Embeddings
from langchain_community.embeddings import BedrockEmbeddings

def test_embedding_invalid():
    with pytest.raises(ValueError, match="'INVALID' is not a valid Embeddings"):
        Embedding(Embeddings("INVALID"), "invalid_model")
        
def test_embedding_valid():
    embedding = Embedding(Embeddings.BEDROCK, "amazon.titan-embed-text-v1")
    assert embedding.model_name == "amazon.titan-embed-text-v1"
    assert embedding.embeddings == Embeddings.BEDROCK

def test_get_embeddings_bedrock():
    embedding = Embedding(Embeddings.BEDROCK, "amazon.titan-embed-text-v1")
    result = get_embeddings(embedding, "us-east-1")
    assert isinstance(result, BedrockEmbeddings)
    assert result.model_id == "amazon.titan-embed-text-v1"


   