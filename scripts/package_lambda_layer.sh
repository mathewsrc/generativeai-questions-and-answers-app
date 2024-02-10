#!/bin/bash

# Create a directory for the python [place the libraries in the /python or python/lib/python3.x/site-packages folders]
mkdir -p temp/python

# Install dependencies 
RUN pip3 install \ 
     --no-cache-dir \
     --platform manylinux2014_x86_64 \
     --target ./temp/python \
     --implementation cp \
     --python-version 3.12 \ 
     --only-binary=:all: --upgrade boto3 \
          langchain \
          langchain-community \
          qdrant-client \
          python-dotenv \
          numpy \
          pypdf

echo "Installed dependencies"

# Create a layer .zip file with the installed libraries at the root [Not required if you are using Terraform]
zip -r lambda_layer.zip ./temp/python
