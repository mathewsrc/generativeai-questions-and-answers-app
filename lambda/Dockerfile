FROM public.ecr.aws/lambda/python:3.12

# Install the specified packages
RUN pip install boto3 \
     langchain \
     langchain-community \
     qdrant-client \
     python-dotenv 

# Copy function code
COPY src/main.py  ${LAMBDA_TASK_ROOT}
COPY src/create_vector_store.py  ${LAMBDA_TASK_ROOT}
COPY src/utils.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "main.lambda_handler" ]