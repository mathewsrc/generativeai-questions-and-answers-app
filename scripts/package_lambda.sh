#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the python [place the libraries in the /python or python/lib/python3.x/site-packages folders]
mkdir -p temp/python

# Install dependencies
pip3 install --platform manylinux2014_x86_64 --target ./temp/python\
 --python-version 3.12 \
 --only-binary=:all: boto3==1.34.17 \
     langchain==0.1.0 \
     langchain-community==0.0.11 \
     qdrant-client==1.7.0 \
     python-dotenv==1.0.1 \
     pypdf==3.17.4 \
     botocore==1.34.17 \
     s3transfer==0.10.0

echo "Installed dependencies"

# Create a layer .zip file with the installed libraries at the root [Not required if you are using Terraform]
#zip -r ../lambda_layer.zip ./temp/python

# Add all *.py files to the root of the .zip file [Not required if you are using Terraform]
#zip ../lambda_payload.zip ./functions/*.py