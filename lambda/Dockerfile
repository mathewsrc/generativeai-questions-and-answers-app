FROM public.ecr.aws/lambda/python:3.11

# Install dependencies using poetry
RUN pip install boto3 \
     langchain \
     langchain-community \
     qdrant-client \
     python-dotenv \
     numpy \
     unstructured

# Copy function code
COPY ./lambda/src/main.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/utils.py ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/create_vector_store.py  ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "main.lambda_handler" ]