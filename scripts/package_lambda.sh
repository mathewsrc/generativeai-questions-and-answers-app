#!/bin/bash

# Move to the lambda directory
cd lambda

# Create a directory for the package
mkdir package

# Install dependencies
pip install --target ./package boto3 langchain-community qdrant-client python-dotenv pydantic

# Move to the package directory
cd package

# Create a .zip file with the installed libraries at the root
zip -r ../lambda_payload.zip .

# Move back to the parent directory
cd ..

# Add all *.py files to the root of the .zip file
zip ./lambda_payload.zip *.py