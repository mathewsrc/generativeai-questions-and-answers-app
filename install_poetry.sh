#!/bin/bash

pipx install --force poetry &&\
poetry completions bash >> ~/.bash_completion &&\
poetry new --src my-project