FROM public.ecr.aws/lambda/python:3.12

# Install dependencies
RUN pip3 install \ 
     --no-cache-dir \
     --platform manylinux2014_x86_64 \
     --target "${LAMBDA_TASK_ROOT}" \
     --implementation cp \
     --python-version 3.12 \ 
     --only-binary=:all: --upgrade boto3 \
          langchain \
          langchain-community \
          qdrant-client \
          python-dotenv \
          pypdf

# Copy function code
COPY ./lambda_functions/src/main.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda_functions/src/utils.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda_functions/src/create_vector_store.py  ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "main.lambda_handler" ]