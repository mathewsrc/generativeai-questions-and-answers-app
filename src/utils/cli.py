import numpy as np
import boto3
import click
from langchain.embeddings import BedrockEmbeddings
from langchain.llms.bedrock import Bedrock
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import PyPDFDirectoryLoader
import glob

boto_session = boto3.Session()
credentials = boto_session.get_credentials()

bedrock_models = boto3.client('bedrock')
bedrock_runtime = boto3.client('bedrock-runtime')


@click.group()
def cli():
    pass

@cli.command('list-models')
def list_models():
    models = bedrock_models.list_foundations_models()
    click.echo(click.style(f'Foundations Models: {models}', fg='green'))
    
    
@cli.command('split-documents')
def split_documents():
    data_path = '../../datasets/'
    pdf_files = glob.glob(data_path + '*.pdf')
    
    # Load documents
    loader = PyPDFDirectoryLoader(data_path)
    documents = loader.load()
    
    # Split documents
    text_splitter = RecursiveCharacterTextSplitter(chuck_size=1000, chunk_overlap=100)
    docs = text_splitter.split_documents(documents)
    

@cli.command('embedding-pdf')
def embedding_pdf():
    bedrock_embeddings = BedrockEmbeddings(client=bedrock_runtime, model_id="amazon.titan-embed-text-v1" )
    llm = Bedrock(client=bedrock_runtime, model_id="anthropic.claude-v2", model_args={'max_tokens_to_sample': 300})
    


if __name__ == '__main__':
    cli()