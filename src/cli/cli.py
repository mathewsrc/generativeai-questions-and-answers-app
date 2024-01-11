import numpy as np
import boto3
import click
import json
import glob
import joblib
from pathlib import Path
from langchain_community.embeddings import BedrockEmbeddings
from langchain.llms.bedrock import Bedrock
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain_community.vectorstores import FAISS
from langchain.indexes.vectorstore import VectorStoreIndexWrapper


boto_session = boto3.Session(region_name='us-east-1')
credentials = boto_session.get_credentials()

bedrock_models = boto3.client("bedrock", region_name='us-east-1')
bedrock_runtime = boto3.client("bedrock-runtime", region_name='us-east-1')
MODEL_ID = "amazon.titan-embed-g1-text-v1"

@click.group()
def cli():
    pass

@cli.command("list-models")
@click.option("--by-provider", help="Filter by provider")
@click.option("--by-output-modality", help="Filter by output modality",
              type=click.Choice(["TEXT", "IMAGE", "EMBEDDING"], case_sensitive=True))
def list_foundation_models(by_provider=None, by_output_modality=None):
    if by_provider is not None and by_output_modality is None:
        models = bedrock_models.list_foundation_models(
            byProvider=by_provider
        )
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    elif by_output_modality is not None and by_provider is None:
        models = bedrock_models.list_foundation_models(
            byOutputModality=by_output_modality
        )
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    elif by_provider is not None and by_output_modality is not None:
        models = bedrock_models.list_foundation_models(byProvider=by_provider, byOutputModality=by_output_modality)
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    else:
        models = bedrock_models.list_foundation_models()
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))


@cli.command("split-documents")
@click.option("--data_path", default="../../datasets/")
@click.option("--chuck_size", default=1000, help="Number of characters per chunk")
@click.option(
    "--chunk_overlap",
    default=100,
    help="Number of characters to overlap between chunks",
)
def split_documents(data_path):
    if not Path(data_path).exists():
        click.echo(click.style(f"Directory {data_path} not found", fg="red"))
        return

    # Load documents
    loader = PyPDFDirectoryLoader(data_path)
    documents = loader.load()

    # Split documents
    text_splitter = RecursiveCharacterTextSplitter(chuck_size=1000, chunk_overlap=100)
    docs = text_splitter.split_documents(documents)
    click.echo(click.style(f"Number of documents loaded: {len(docs)}", fg="green"))
    click.echo(click.style(f"Number of documents after split: {len(docs)}", fg="green"))

    # Save documents
    for i, doc in enumerate(docs):
        with open(f"../../datasets/pdf_docs/{i}.txt", "w") as f:
            f.write(doc.page_content)


@cli.command("create-vectorstore-in-memory")
@click.option(
    "--model_id",
    default="amazon.titan-embed-text-v1",
    type=click.Choice(["amazon.titan-embed-text-v1"], case_sensitive=True),
)
@click.option("--data_path", default="../../datasets/pdf_docs/")
def create_vectorstore_in_memory(model_id, data_path):
    bedrock_embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_id)
    txt_files = glob.glob(data_path + "*.txt")

    if not Path(data_path).exists():
        click.echo(click.style(f"Directory {data_path} not found", fg="red"))
        return

    docs = []
    for txt_file in txt_files:
        with open(txt_file, "r") as f:
            docs.append(f.read())

    vectorestore_faiss = FAISS.from_documents(docs, bedrock_embeddings)
    wrapper_vectorestore_faiss = VectorStoreIndexWrapper(vectorestore_faiss)

    # save vectorstore
    vectorstore_path = "../../datasets/vectorstore_faiss.pkl"
    joblib.dump(wrapper_vectorestore_faiss, vectorstore_path)
    click.echo(click.style(f"Vectorstore saved in {vectorstore_path}", fg="green"))


@cli.command("question-answering")
@click.option("--question", prompt=True)
@click.option(
    "--max_tokens", default=100, help="Maximum number of tokens to sample from the model"
)
@click.option(
    "--model_id",
    default="anthropic.claude-v2",
    type=click.Choice(["anthropic.claude-v2"], case_sensitive=True),
)
def question_aswering(question, max_tokens, model_id):
    try:
        wrapper_vectorestore_faiss = joblib.load("../../datasets/vectorstore_faiss.pkl")
    except:
        click.echo(click.style(f"Vectorstore not found, creating one...", fg="red"))
        return
    llm = Bedrock(
        client=bedrock_runtime,
        model_id=model_id,
        model_args={"max_tokens_to_sample": max_tokens},
    )
    answer = wrapper_vectorestore_faiss.query(question=question, llm=llm)
    click.echo(click.style(f"Answer: {answer}", fg="green"))


if __name__ == "__main__":
    cli()
