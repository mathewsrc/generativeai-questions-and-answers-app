#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the package
mkdir package

# Install dependencies
pip install --target ./package boto3 langchain-community qdrant-client python-dotenv

# Move to the package directory
cd package

# Create a layer .zip file with the installed libraries at the root
zip -r ../../lambda_layer.zip .

# Move to the functions directory
cd ../functions

# Add all *.py files to the root of the .zip file
zip ../lambda_payload.zip *.py