# create a hello world fastapi
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import boto3
import joblib
from langchain.llms import Bedrock

class Question(BaseModel):
    content: str

app = FastAPI()
bedrock_runtime = boto3.client("bedrock-runtime")
boto_session = boto3.Session()
credentials = boto_session.get_credentials()

bedrock_models = boto3.client("bedrock")
bedrock_runtime = boto3.client("bedrock-runtime")

@app.get("/", response_class=HTMLResponse)
async def root():
    return HTMLResponse("""
    <h1>Welcome to our Question/Answering application with Bedrock</h1>
    <p>Use the /question endpoint to ask a question.</p>
    """)

@app.get("/question", response_class=HTMLResponse)
async def question(question: Question):
    llm = Bedrock(
        client=bedrock_runtime,
        model_id="anthropic.claude-v2",
    )
    try:
        answer = "Hello from FastAPI"
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return HTMLResponse(f"<h1>Question: {question.content}</h1><p>Answer: {answer}</p>")
