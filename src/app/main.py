# create a hello world fastapi
from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn
import boto3
from pathlib import Path
import joblib
from langchain.embeddings import BedrockEmbeddings
from langchain.llms import Bedrock


class Question(BaseModel):
    content: str

app = FastAPI()
boto_session = boto3.Session()
credentials = boto_session.get_credentials()

bedrock_models = boto3.client("bedrock")
bedrock_runtime = boto3.client("bedrock-runtime")

@app.get("/")
async def root():
    return {"message": "Hello from Docker"}

@app.get("/question")
async def question(question: Question):
    try:
        wrapper_vectorestore_faiss = joblib.load("../../datasets/vectorstore_faiss.pkl")
    except:
        return {"message": "Error loading VectorStore"}
    llm = Bedrock(
        client=bedrock_runtime,
        model_id="anthropic.claude-v2",
        model_args={"max_tokens_to_sample": 200},
    )
    answer = wrapper_vectorestore_faiss.query(question=question, llm=llm)
    
    return {"question": question.content, "answer": answer}
