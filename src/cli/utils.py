from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
import click
from langchain_community.embeddings.huggingface import HuggingFaceEmbeddings


def get_embeddings(model_name):
    model_kwargs = {'device': 'cpu'}
    encode_kwargs = {'normalize_embeddings': False}
    embeddings =  HuggingFaceEmbeddings(
        model_name=model_name,
        model_kwargs=model_kwargs,
        encode_kwargs=encode_kwargs
    
    )
    click.echo(click.style(f"Embedding finished!", fg="green"))
    return embeddings

def get_documents_from_pdf():    
    # Load documents
    loader = PyPDFDirectoryLoader("./documents/immigration")
    documents = loader.load()

    # Split documents
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
    docs = text_splitter.split_documents(documents)
    click.echo(click.style(f"Number of documents after split: {len(docs)}", fg="green"))
    return docs