import numpy as np
import boto3

boto_session = boto3.Session()
credentials = boto_session.get_credentials()

bedrock_models = boto3.client('bedrock')