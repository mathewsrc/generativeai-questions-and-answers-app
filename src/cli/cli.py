import numpy as np
import boto3
import click
import json
import joblib
from pathlib import Path
from langchain_community.embeddings import BedrockEmbeddings
from langchain.llms.bedrock import Bedrock
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain_community.vectorstores import Qdrant
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA


from global_variables import (
    VECTORSTORE_PATH,
    DOCUMENTS_PATH,
    AWS_REGION,
    EMBEDDING_MODEL,
    AWS_S3_BUCKET,
    BEDROCK_TEXT_MODEL,
)
from qdrant_client import QdrantClient

qdrant_client = QdrantClient("localhost", port=6333)

boto_session = boto3.Session(region_name=AWS_REGION)
credentials = boto_session.get_credentials()

# bedrock
bedrock_models = boto3.client("bedrock", region_name=AWS_REGION)
bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_REGION)


@click.group()
def cli():
    pass


@cli.command("download-docs")
def download_files():
    s3 = boto3.resource("s3")
    bucket = s3.Bucket(AWS_S3_BUCKET)
    for obj in bucket.objects.all():
        key = obj.key
        if key.endswith(".pdf"):
            bucket.download_file(key, f"{DOCUMENTS_PATH}/{key}")
            click.echo(click.style(f"Downloaded {key}", fg="green"))


@cli.command("list-models")
@click.option("--by-provider", help="Filter by provider")
@click.option(
    "--by-output-modality",
    help="Filter by output modality",
    type=click.Choice(["TEXT", "IMAGE", "EMBEDDING"], case_sensitive=True),
)
def list_foundation_models(by_provider=None, by_output_modality=None):
    if by_provider is not None and by_output_modality is None:
        models = bedrock_models.list_foundation_models(byProvider=by_provider)
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    elif by_output_modality is not None and by_provider is None:
        models = bedrock_models.list_foundation_models(
            byOutputModality=by_output_modality
        )
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    elif by_provider is not None and by_output_modality is not None:
        models = bedrock_models.list_foundation_models(
            byProvider=by_provider, byOutputModality=by_output_modality
        )
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
    else:
        models = bedrock_models.list_foundation_models()
        click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))


@cli.command("split-documents")
@click.option("--data_path", default=DOCUMENTS_PATH, help="Path to documents")
@click.option("--chunk_size", default=1000, help="Number of characters per chunk")
@click.option(
    "--chunk_overlap",
    default=100,
    help="Number of characters to overlap between chunks",
)
def split_documents(data_path, chunk_size, chunk_overlap):
    if not Path(data_path).exists():
        click.echo(click.style(f"Directory {data_path} not found", fg="red"))
        return

    # Load documents
    loader = PyPDFDirectoryLoader(f"{data_path}/*.pdf")
    documents = loader.load()

    # Split documents
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size, chunk_overlap=chunk_overlap
    )
    docs = text_splitter.split_documents(documents)
    click.echo(click.style(f"Number of documents loaded: {len(docs)}", fg="green"))
    click.echo(click.style(f"Number of documents after split: {len(docs)}", fg="green"))

    docs_path = f"./docs.joblib"
    joblib.dump(docs, docs_path)
    click.echo(click.style(f"Documents saved in {docs_path}", fg="green"))


@cli.command("create-vectorstore-in-memory")
@click.option(
    "--model_id",
    default=EMBEDDING_MODEL,
    type=click.Choice(["amazon.titan-embed-text-v1"], case_sensitive=True),
)
@click.option("--data_path", default=DOCUMENTS_PATH, help="Path to documents")
def create_vectorstore_in_memory(model_id, data_path):
    if Path(f"./docs.joblib").exists():
        docs = joblib.load(f"./docs.joblib")
        click.echo(click.style(f"File ./docs.joblib not found", fg="red"))
        return

    bedrock_embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id=model_id)

    Qdrant.from_documents(
        docs,
        bedrock_embeddings,
        location=":memory:",  # Local mode with in-memory storage only
        collection_name="my_documents",
        force_recreate=False,
    )


@cli.command("question")
@click.option("--question", prompt=True)
@click.option(
    "--max_tokens",
    default=200,
    help="Maximum number of tokens to sample from the model",
)
@click.option(
    "--model_id",
    default=BEDROCK_TEXT_MODEL,
    type=click.Choice(["anthropic.claude-v2"], case_sensitive=True),
)
def question(question, max_tokens, model_id):
    # Load documents
    loader = PyPDFDirectoryLoader("./documents")
    documents = loader.load()

    # Split documents
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
    docs = text_splitter.split_documents(documents)

    bedrock_embeddings = BedrockEmbeddings(
        client=bedrock_runtime, model_id=EMBEDDING_MODEL
    )

    # vectorstore = Qdrant(
    #         embeddings=bedrock_embeddings,
    #         collection_name="my_documents",
    #         client=qdrant_client,
    #     )

    vectorstore = Qdrant.from_documents(
        docs,
        bedrock_embeddings,
        location=":memory:",  # Local mode with in-memory storage only
        collection_name="my_documents",
        force_recreate=False,
    )

    prompt_template = """

    Human: Use the following pieces of context to provide a concise answer to the question at the end. 
    <context>
    {context}
    </context

    Question: {question}

    Assistant:"""

    PROMPT = PromptTemplate(
        template=prompt_template, input_variables=["context", "question"]
    )

    inference_modifier = {
        "max_tokens_to_sample": 200,
        "temperature": 0.5,
        "top_k": 250,
        "top_p": 1,
        "stop_sequences": ["\n\nHuman"],
    }

    llm = Bedrock(
        model_id=model_id, client=bedrock_runtime, model_kwargs=inference_modifier
    )

    qa = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=vectorstore.as_retriever(
            search_type="similarity", search_kwargs={"k": 3}
        ),
        return_source_documents=True,
        chain_type_kwargs={"prompt": PROMPT, "verbose": False},
    )

    result = qa({"query": question})
    answer = result["result"]
    click.echo(click.style(f"\nAnswer: {answer}", fg="green"))


if __name__ == "__main__":
    cli()
