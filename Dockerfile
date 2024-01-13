FROM python:3.11.2-buster

# Install curl and curl the poetry installer
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive && \
  apt install -y curl && \
  curl -sSL https://install.python-poetry.org | python

# Sets the PATH to get the poetry bin
ENV PATH="/root/.local/bin:${PATH}"

# Set the working directory
WORKDIR /code

# Copy the files to the working directory
COPY ./pyproject.toml /code/pyproject.toml
COPY ./poetry.lock /code/poetry.lock 
COPY ./README.md /code/README.md
COPY ./src/app /code/app

# Configure poetry to create virtualenvs inside the project and install dependencies
RUN poetry config virtualenvs.in-project true && \
  poetry install

# Defines the port that the application listens on
EXPOSE 8000

# Run the application using unicorn on port 8000
CMD ["poetry", "run", "uvicorn", "--host", "0.0.0.0", "--port", "8000", "app.main:app", "--reload"]
