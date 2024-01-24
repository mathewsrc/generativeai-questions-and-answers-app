from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import boto3
from botocore.exceptions import ClientError
from langchain_community.llms.bedrock import Bedrock
import os
from dotenv import load_dotenv
from qdrant_client import QdrantClient
from langchain_community.vectorstores.qdrant import Qdrant
from langchain_community.embeddings.bedrock import BedrockEmbeddings
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA

COLLECTION_NAME = "cnu" # replace with your collection name
BEDROCK_MODEL_NAME = "anthropic.claude-v2"
BEDROCK_EMBEDDINGS_MODEL_NAME = "amazon.titan-embed-text-v1"

app = FastAPI()

class Body(BaseModel):
    text: str

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
AWS_REGION = 'us-east-1'

boto_session = boto3.Session(region_name=AWS_REGION)
credentials = boto_session.get_credentials()
bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_REGION)

prompt_template = """
                Use the following pieces of context to provide a concise answer to the question at the end. 
                If you don't know the answer, just say that you don't know, don't try to make up an answer.
                                
                Question: {question}
                                
                {context}

                Answer:
            """
            
def get_secret(secret_name):
    client = boto_session.client(
        service_name='secretsmanager',
        region_name=AWS_REGION
    )
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    return get_secret_value_response['SecretString']
    
    
def get_bedrock_embeddings(model_name: str) -> BedrockEmbeddings:
	embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_name)
	return embeddings

@app.get("/", response_class=HTMLResponse)
async def root():
	return HTMLResponse(
		"""
    <h1>Welcome to our Question/Answering application with Bedrock</h1><br>
    <p>Use the /question endpoint to ask a question.</p>
    """
	)

@app.post("/ask", response_class=HTMLResponse)
async def question(body:Body):
	try:
		if QDRANT_URL is None:
			qdrant_url = get_secret("prod/qdrant_url")

		if QDRANT_API_KEY is None:
			qdrant_api_key = get_secret("prod/qdrant_api_key")
  
		client =  QdrantClient(url=qdrant_url, api_key=qdrant_api_key)
		embeddings = get_bedrock_embeddings(BEDROCK_EMBEDDINGS_MODEL_NAME)
		
		qdrant = Qdrant(
					client=client,
					embeddings=embeddings,
					collection_name=COLLECTION_NAME,
				)

		prompt = PromptTemplate(template=prompt_template, input_variables=["context", "question"])

		# Bedrock Hyperparameters
		inference_modifier = {
			"max_tokens_to_sample": 100,
			"temperature": 0.5,
			"top_k": 250,
			"top_p": 1,
			"stop_sequences": [f"\n\nHuman"],
		}

		llm = Bedrock(model_id=BEDROCK_MODEL_NAME, 
                client=bedrock_runtime, 
                model_kwargs=inference_modifier)
		
		qa = RetrievalQA.from_chain_type(
			llm=llm,
			chain_type="stuff",
			retriever=qdrant.as_retriever(search_kwargs={"k": 2}),
			return_source_documents=False,
			chain_type_kwargs={"prompt": prompt, "verbose": False},
		)

		result = qa.invoke(input={"query": body.text})
		answer = result["result"]
	except Exception as e:
		raise HTTPException(status_code=500, detail=str(e))
	return HTMLResponse(f"<h1>Question: {body.text}</h1><p>Answer: {answer}</p>")
