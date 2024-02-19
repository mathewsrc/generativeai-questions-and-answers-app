#!/bin/bash

# check if Environment variables are not set, ask user to enter them
if [ -z "$QDRANT_URL" ]; then
	echo "Please enter QDRANT_URL"
	read QDRANT_URL
fi

if [ -z "$QDRANT_API_KEY" ]; then
	echo "Please enter QDRANT_API_KEY"
	read QDRANT_API_KEY
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
	echo "Please enter AWS_ACCESS_KEY_ID"
	read AWS_ACCESS_KEY_ID
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
	echo "Please enter AWS_SECRET_ACCESS_KEY"
	read AWS_SECRET_ACCESS_KEY
fi

docker run -p 80:80 \
	-e QDRANT_URL=$QDRANT_URL \
	-e QDRANT_API_KEY=$QDRANT_API_KEY \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
	app 