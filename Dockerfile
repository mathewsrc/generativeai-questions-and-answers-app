FROM python:3.11.2-buster

ENV DEBIAN_FRONTEND='noninteractive'

RUN apt-get update && apt install -y curl
RUN curl -sSL https://install.python-poetry.org | python

ENV PATH="${PATH}:/root/.local/bin"
RUN poetry config virtualenvs.in-project true

WORKDIR /code

COPY ./pyproject.toml /code/pyproject.toml
COPY ./poetry.lock /code/poetry.lock
COPY ./README.md /code/README.md
COPY ./src/app /code/app

RUN poetry install

EXPOSE 8000

CMD [ "poetry","run","uvicorn","--host","0.0.0.0","--port","8000","app.main:app","--reload"]