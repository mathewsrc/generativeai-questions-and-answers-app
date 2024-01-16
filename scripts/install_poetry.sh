#!/bin/bash

# This script is used to install Poetry

pipx install --force poetry 
poetry completions bash >> ~/.bash_completion 
poetry init
poetry install
poetry --version