from langchain_community.vectorstores.qdrant import Qdrant
from qdrant_client import QdrantClient
import click
import os
from dotenv import load_dotenv
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
from global_variables import COLLECTION_NAME
from transformers import (AutoModelForCausalLM, 
                          AutoTokenizer, pipeline)
from langchain_community.llms.huggingface_pipeline import HuggingFacePipeline
from utils import get_embeddings, get_documents_from_pdf
from qdrant_client import models

load_dotenv()

QDRANT_URL = os.environ.get('QDRANT_URL')
QDRANT_API_KEY = os.environ.get('QDRANT_API_KEY')

def get_client(url, api_key):
    return QdrantClient(url=QDRANT_URL, 
                          api_key=QDRANT_API_KEY)

@click.group()
def cli():
    pass

@cli.command("create")
@click.option('--url', default=QDRANT_URL, help='Qdrant server URL')
@click.option('--api-key', default=QDRANT_API_KEY, help='Qdrant API key')
@click.option('--collection_name', default=COLLECTION_NAME, help='Qdrant collection name')
@click.option('--embedding_model', default = "sentence-transformers/all-MiniLM-L6-v2",
              type=click.Choice(["BAAI/bge-small-en",
                                 "sentence-transformers/all-MiniLM-L6-v2",
                                 "sentence-transformers/all-mpnet-base-v2",
                                 "sentence-transformers/all-distilroberta-v1"]),
              help='HuggingFace embedding model name')
def create_vectostore(url, api_key, collection_name, embedding_model):
    try: 
        docs = get_documents_from_pdf()
        embeddings = get_embeddings(model_name=embedding_model)
        click.echo(click.style(f"Creating collection!", fg="green"))
                
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
        click.echo(click.style(f"Collection created!", fg="green"))
    except Exception as e:
        click.echo(click.style(f"Error: {e}", fg="red"))
        return
    return vectorstore

@cli.command("delete")
@click.option('--url', default=QDRANT_URL, help='Qdrant server URL')
@click.option('--api-key', default=QDRANT_API_KEY, help='Qdrant API key')
@click.option('--collection_name', default=COLLECTION_NAME, help='Qdrant collection name')
def delete_collection(url, api_key, collection_name):
    try:
        client = get_client(url, api_key)
        client.delete_collection(collection_name=collection_name)
        click.echo(click.style(f"Collection deleted!", fg="green"))
    except:
        click.echo(click.style(f"Error deleting collection!", fg="red"))
    
@cli.command("info")
@click.option('--url', default=QDRANT_URL, help='Qdrant server URL')
@click.option('--api-key', default=QDRANT_API_KEY, help='Qdrant API key')
@click.option('--collection_name', default=COLLECTION_NAME, help='Qdrant collection name')
def info(url, api_key, collection_name):
    try:
        client = get_client(url, api_key)
        info = client.get_collection(collection_name=collection_name)
        click.echo(click.style(f"Collection info: {info}", fg="green"))
    except Exception as e:
        click.echo(click.style(f"Error: {e}", fg="red"))

@cli.command("ask")
@click.option('--question', required=True, type=str, prompt=True, help='What do you like to ask?')
@click.option('--url', default=QDRANT_URL, help='Qdrant server URL')
@click.option('--api-key', default=QDRANT_API_KEY, help='Qdrant API key')
@click.option('--collection_name', default=COLLECTION_NAME, help='Qdrant collection name')
@click.option('--model_name', default = "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
              type=click.Choice(["meta-llama/Llama-2-7b-chat-hf",
                                 "microsoft/phi-2", #5G
                                 "TinyLlama/TinyLlama-1.1B-Chat-v1.0" #2.2G
                             ]),
              help='HuggingFace Text-Generation model name')
@click.option('--embedding_model', default = "sentence-transformers/all-MiniLM-L6-v2",
              type=click.Choice(["BAAI/bge-small-en",
                                 "sentence-transformers/all-MiniLM-L6-v2",
                                 "sentence-transformers/all-mpnet-base-v2",
                                 "sentence-transformers/all-distilroberta-v1"]),
              help='HuggingFace embedding model name')
def ask(question, url, api_key, collection_name, model_name, embedding_model):
    try:
         # Ask for confirmation
        confirmation = click.confirm("""
                                     This will donwload the model locally.
                                     Do you want to continue?
                                     """)
    
        if confirmation:
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModelForCausalLM.from_pretrained(model_name)
            pipe = pipeline("text-generation", 
                            model=model, 
                            tokenizer=tokenizer,
                            token=os.environ.get('HUGGINGFACE_TOKEN'),
                            )
            llm = HuggingFacePipeline(pipeline=pipe,
                                    model_kwargs={"temperature": 0.4, "max_length": 500})
            
            client = get_client(url, api_key)
            retriever = Qdrant(client=client,
                            embeddings=get_embeddings(model_name=embedding_model),
                            collection_name=collection_name).as_retriever(search_type="similarity", 
                                                                        search_kwargs={"k":2})
            
            prompt_template = """Use the following pieces of context to answer the question at the end.
                                If you don't know the answer, just say that you don't know, don't try to make up an answer.
                                Use three sentences maximum and keep the answer as concise as possible.
                                Always say "thanks for asking!" at the end of the answer.

                                Question: {question}
                                
                                {context}

                                Helpful Answer:"""

            prompt = PromptTemplate.from_template(prompt_template)
            
            chain = RetrievalQA.from_chain_type(
                llm=llm,
                chain_type="stuff",
                retriever=retriever,
                return_source_documents=True,
                chain_type_kwargs={"prompt": prompt, "verbose": False},
            )
            result = chain.invoke({"query": question})
            click.echo(click.style(f"\nAnswer: {result['result']}", fg="green"))
        else:
            click.echo(click.style(f"Exiting...", fg="red"))
            return
    except Exception as e:
        click.echo(click.style(f"Error: {e}", fg="red"))
        return
    
if __name__ == "__main__":
    cli()