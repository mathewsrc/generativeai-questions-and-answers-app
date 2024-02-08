#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the python [place the libraries in the /python or python/lib/python3.x/site-packages folders]
mkdir -p temp/python

# Install dependencies 
pip install \
    --ignore-installed \
    --no-cache-dir \
    --platform manylinux2014_x86_64 \
    --target ./temp/python \
    --implementation cp \
    --python-version 3.11 \
    --only-binary=:all: --upgrade \
     langchain \
     langchain-community \
     qdrant-client \
     python-dotenv \
     unstructured \
     numpy

echo "Installed dependencies"

# Create a layer .zip file with the installed libraries at the root [Not required if you are using Terraform]
#zip -r lambda_layer.zip ./temp/python

# Add all *.py files to the root of the .zip file [Not required if you are using Terraform]
#zip lambda_payload.zip ./src/*.py