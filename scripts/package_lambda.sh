#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the python [place the libraries in the /python or python/lib/python3.x/site-packages folders]
mkdir -p temp/python

# Install dependencies
pip3 install --platform manylinux2014_x86_64 --target ./temp/python\
 --python-version 3.12 \
 --only-binary=:all: boto3 \
    langchain \
    langchain-community \
    qdrant-client \
    python-dotenv \
    unstructured \
    pypdf

# Create a layer .zip file with the installed libraries at the root [Not required if you are using Terraform]
#zip -r ../lambda_layer.zip ./temp/python

# Add all *.py files to the root of the .zip file [Not required if you are using Terraform]
#zip ../lambda_payload.zip ./functions/*.py