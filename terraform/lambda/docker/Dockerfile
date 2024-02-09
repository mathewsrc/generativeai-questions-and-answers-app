FROM public.ecr.aws/lambda/python:3.12

# Lambda only permit write files in /tmp
ENV NLTK_DATA="tmp/"

# Install dependencies using poetry
RUN pip3 install \ 
     --no-cache-dir \
     --platform manylinux2014_x86_64 \
     --target ${LAMBDA_TASK_ROOT} \
     --implementation cp \
     --python-version 3.12 \ 
     --only-binary=:all: --upgrade boto3 \
          langchain \
          langchain-community \
          qdrant-client \
          python-dotenv \
          numpy \
          unstructured \
          unstructured[pdf] \
          nltk

# Copy function code
COPY ./lambda/src/main.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/utils.py  ${LAMBDA_TASK_ROOT}
COPY ./lambda/src/create_vector_store.py  ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "main.lambda_handler" ]