import boto3
from opensearchpy import RequestsHttpConnection
from requests_aws4auth import AWS4Auth
from langchain_community.vectorstores import OpenSearchVectorSearch


def get_docs():
    return None

def get_embeddings():
    return None

service = "aoss"  # must set the service as 'aoss'
region = "us-east-2"

def get_awsauth():
    credentials = boto3.Session(
        aws_access_key_id="xxxxxx", aws_secret_access_key="xxxxx"
    ).get_credentials()
    awsauth = AWS4Auth("xxxxx", "xxxxxx", region, service, session_token=credentials.token)
    return awsauth

def create_vectostore():
    docs = get_docs()
    embeddings = get_embeddings()
    awsauth = get_awsauth()

    return OpenSearchVectorSearch.from_documents(
        docs,
        embeddings,
        opensearch_url="host url",
        http_auth=awsauth,
        timeout=300,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        index_name="test-index-using-aoss",
        engine="faiss",
    )

    # docs = docsearch.similarity_search(
    #     "What is feature selection",
    #     efficient_filter=filter,
    #     k=200,
    # )