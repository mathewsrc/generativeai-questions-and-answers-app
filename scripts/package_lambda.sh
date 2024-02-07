#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the python [place the libraries in the /python or python/lib/python3.x/site-packages folders]
mkdir -p python

# Install dependencies
pip3 install --platform manylinux2014_x86_64 --target ./python --python-version 3.12 --only-binary=:all: boto3 langchain-community qdrant-client python-dotenv

# Create a layer .zip file with the installed libraries at the root
zip -r ../lambda_layer.zip ./python

# Add all *.py files to the root of the .zip file
zip ../lambda_payload.zip ./functions/*.py