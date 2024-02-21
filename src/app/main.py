from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import boto3
from botocore.exceptions import ClientError
from langchain_community.llms.bedrock import Bedrock
import os
from dotenv import load_dotenv
from qdrant_client import AsyncQdrantClient, QdrantClient
from langchain_community.vectorstores.qdrant import Qdrant
from langchain_community.embeddings.bedrock import BedrockEmbeddings
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

COLLECTION_NAME = "cnu"  # replace with your collection name
BEDROCK_MODEL_NAME = "anthropic.claude-v2"
BEDROCK_EMBEDDINGS_MODEL_NAME = "amazon.titan-embed-text-v1"
AWS_DEFAULT_REGION = "us-east-1"

app = FastAPI()

class Body(BaseModel):
	text: str
	temperature: float = 0.5

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

	client = session.client(service_name="secretsmanager", region_name=AWS_DEFAULT_REGION)
	try:
		get_secret_value_response = client.get_secret_value(SecretId=secret_name)
	except ClientError as e:
		raise e
	return get_secret_value_response["SecretString"]


def get_bedrock_embeddings(model_name: str, bedrock_runtime) -> BedrockEmbeddings:
	embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_name)
	return embeddings


@app.get("/", response_class=HTMLResponse)
async def root():
	return HTMLResponse(
		"""
    <h1>Welcome to our Question/Answering application where you can ask 
    questions about the Concurso Nacional Unificado</h1><br>
    <p>Use the /ask endpoint to ask a question.</p>
    """
	)
 
@app.get("/collectioninfo")
async def collection_info():
    try:
        # Get the Qdrant URL and API key from the environment variables
        qdrant_url = os.environ.get("QDRANT_URL")
        qdrant_api_key = os.environ.get("QDRANT_API_KEY")

	    # If the environment variables are not set, get the secrets from AWS Secrets Manager		
        if qdrant_url is None:
            qdrant_url = get_secret("prod/qdrant_url")

        if qdrant_api_key is None:
            qdrant_api_key = get_secret("prod/qdrant_api_key")
            
        asyncClient = AsyncQdrantClient(url=qdrant_url, 
					api_key=qdrant_api_key,
					port=443, 
					grpc_port=6334)
        
        info = await asyncClient.get_collection(collection_name=COLLECTION_NAME)
        
        logger.info(f"Collection info: {info}")
        return {"collection_info": info}
    except Exception as e:
        logger.info(f"Error: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting collection info:{e}")

@app.post("/ask_only")
def ask(body: Body):
	import json
	
	body = json.dumps({
        "prompt": f"Human:{body.text}\n Assistant:",
		"max_tokens_to_sample": 100,
		"temperature": body.temperature,
		"top_k": 250,
		"top_p": 1,
		"stop_sequences": ["\n\nHuman"],
	})

	accept = 'application/json'
	contentType = 'application/json'

	bedrock = boto3.client("bedrock-runtime", region_name=AWS_DEFAULT_REGION)
	response = bedrock.invoke_model(body=body, modelId=BEDROCK_MODEL_NAME, accept=accept, contentType=contentType)

	response_body = json.loads(response.get('body').read())

	return {"answer": response_body}

@app.post("/ask")
async def question(body: Body):
	start_time = time.time()

	answer = ""
	
	# Get the Qdrant URL and API key from the environment variables
	qdrant_url = os.environ.get("QDRANT_URL")
	qdrant_api_key = os.environ.get("QDRANT_API_KEY")

	# Create a Bedrock runtime client
	bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_DEFAULT_REGION)

	# If the environment variables are not set, get the secrets from AWS Secrets Manager		
	if qdrant_url is None:
		qdrant_url = get_secret("prod/qdrant_url")

	if qdrant_api_key is None:
		qdrant_api_key = get_secret("prod/qdrant_api_key")

	# Create a Qdrant client
	asyncClient = AsyncQdrantClient(url=qdrant_url, 
					api_key=qdrant_api_key,
					port=443, 
					grpc_port=6334)

	client = QdrantClient(url=qdrant_url, 
					api_key=qdrant_api_key,
					port=443, 
					grpc_port=6334)
	
	logger.info("Qdrant client created successfully")

	# Get a Bedrock embeddings model
	embeddings = get_bedrock_embeddings(BEDROCK_EMBEDDINGS_MODEL_NAME, bedrock_runtime)

	# Create a Qdrant retriever
	qdrant = Qdrant(
		client=client,
		async_client=asyncClient,
		embeddings=embeddings,
		collection_name=COLLECTION_NAME,
	).as_retriever(search_kwargs={"k": 2})

	# Create a prompt
	prompt = PromptTemplate(template=prompt_template, input_variables=["context", "question"])

	# Bedrock Hyperparameters
	inference_modifier = {
		"max_tokens_to_sample": 100,
		"temperature": body.temperature,
		"top_k": 250,
		"top_p": 1,
		"stop_sequences": ["\n\nHuman"],
	}

	# Get Bedrock LLM
	llm = Bedrock(
		model_id=BEDROCK_MODEL_NAME, client=bedrock_runtime, model_kwargs=inference_modifier
	)
 
	# Create a retrieval QA chain
	qa = RetrievalQA.from_chain_type(
		llm=llm,
		chain_type="stuff",
		retriever=qdrant,
		return_source_documents=False,
		chain_type_kwargs={"prompt": prompt, "verbose": False},
	)

	logger.info("Invoking the model")

	# Invoke the model
	result = await qa.ainvoke(input={"query": body.text})
	answer = result["result"]
	end_time = time.time()

	elapsed_time = end_time - start_time

	logger.info(f"{elapsed_time:.2} seconds to complete.")
	return {"answer": answer,"time": f"{elapsed_time:.2} seconds."}

	