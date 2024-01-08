import numpy as np
import boto3
import json
from fastapi import FastAPI, Response
from pydantic import BaseModel
import uvicorn

# boto_session = boto3.Session()
# credentials = boto_session.get_credentials()

# bedrock_models = boto3.client('bedrock')

# MODEL_ID = 'amazon.titan-embed-g1-text-v1'

# Create FastAPI instance
app = FastAPI()

# Define Pydantic model
class Item(BaseModel):
    text: str
    
@app.get('/')
def root():
    return Response("<h1>API to Question and Answering</h1>")
    
# Define API route
@app.post("/predict")
def predict(item: Item):
    return {"text": item.text}





    