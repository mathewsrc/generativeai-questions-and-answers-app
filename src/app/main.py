import boto3
import logging
import os
import time
from botocore.exceptions import ClientError
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain_community.embeddings.bedrock import BedrockEmbeddings
from langchain_community.llms.bedrock import Bedrock
from langchain_community.vectorstores.qdrant import Qdrant
from pydantic import BaseModel
from qdrant_client import AsyncQdrantClient, QdrantClient

COLLECTION_NAME = "cnu"
BEDROCK_MODEL_NAME = "anthropic.claude-v2"
BEDROCK_EMBEDDINGS_MODEL_NAME = "amazon.titan-embed-text-v1"
AWS_DEFAULT_REGION = "us-east-1"

# Logging setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = FastAPI()

class Body(BaseModel):
    text: str
    temperature: float = 0.5

# Load environment variables
load_dotenv()

session = boto3.Session(region_name=AWS_DEFAULT_REGION)

prompt_template = """
    Use the following pieces of context to provide a concise answer to the question at the end. 
    If you don't know the answer, just say that you don't know, don't try to make up an answer.
    Human: {question}
    {context}
    Assistant:
"""

def get_secret(secret_name):
    """ Get the secret from AWS Secrets Manager."""
    client = session.client(service_name="secretsmanager", region_name=AWS_DEFAULT_REGION)
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        raise e
    secret = get_secret_value_response["SecretString"]
    if not isinstance(secret, str):
        secret = str(secret)
    return secret

def get_bedrock_embeddings(model_name: str, bedrock_runtime) -> BedrockEmbeddings:
    """Get the Bedrock embeddings Model"""
    embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_name)
    return embeddings

@app.get("/", response_class=HTMLResponse)
async def root():
    """Root endpoint."""
    return HTMLResponse(
        """
        <h1>Welcome to our Question/Answering application where you can ask 
        questions about the Concurso Nacional Unificado</h1><br>
        <p>Use the /ask endpoint to ask a question.</p>
        """
    )

@app.get("/collectioninfo")
async def collection_info():
    """Get the collection info from Qdrant."""
    try:
        qdrant_url = os.getenv("QDRANT_URL") or get_secret("prod/qdrant_url")
        qdrant_api_key = os.getenv("QDRANT_API_KEY") or get_secret("prod/qdrant_api_key")
        
        async_client = AsyncQdrantClient(
            url=qdrant_url, 
            api_key=qdrant_api_key,
            port=6333, 
            grpc_port=6334,
            timeout=10
        )
        
        info = await async_client.get_collection(collection_name=COLLECTION_NAME)
        
        logger.info(f"Collection info: {info}")
        return {"collection_info": info}
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting collection info:{e}")

@app.post("/ask")
async def question(body: Body):
    """Ask a question and get an answer from the model."""
    try:
        start_time = time.time()
        
        qdrant_url = os.getenv("QDRANT_URL") or get_secret("prod/qdrant_url")
        qdrant_api_key = os.getenv("QDRANT_API_KEY") or get_secret("prod/qdrant_api_key")

        bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_DEFAULT_REGION)

        async_client = AsyncQdrantClient(
            url=qdrant_url, 
            api_key=qdrant_api_key,
            port=6333, 
            grpc_port=6334
        )

        client = QdrantClient(
            url=qdrant_url, 
            api_key=qdrant_api_key,
            port=6333, 
            grpc_port=6334
        )
        
        logger.info("Qdrant client created successfully")

        embeddings = get_bedrock_embeddings(BEDROCK_EMBEDDINGS_MODEL_NAME, bedrock_runtime)

        qdrant = Qdrant(
            client=client,
            async_client=async_client,
            embeddings=embeddings,
            collection_name=COLLECTION_NAME,
        ).as_retriever(search_kwargs={"k": 2})

        prompt = PromptTemplate(template=prompt_template, input_variables=["context", "question"])

        inference_modifier = {
            "max_tokens_to_sample": 100,
            "temperature": body.temperature,
            "top_k": 250,
            "top_p": 1,
            "stop_sequences": ["\n\nHuman"],
        }

        llm = Bedrock(
            model_id=BEDROCK_MODEL_NAME, client=bedrock_runtime, model_kwargs=inference_modifier
        )
    
        qa = RetrievalQA.from_chain_type(
            llm=llm,
            chain_type="stuff",
            retriever=qdrant,
            return_source_documents=False,
            chain_type_kwargs={"prompt": prompt, "verbose": False},
        )

        logger.info("Invoking the model")

        result = await qa.ainvoke(input={"query": body.text})
        answer = result["result"]
        elapsed_time = time.time() - start_time

        logger.info(f"{elapsed_time:.2f} seconds to complete.")
        return {"answer": answer,"time": f"{elapsed_time:.2f} seconds."}
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))