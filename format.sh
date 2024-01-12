#!/usr/bin/env bash

for DIR in */; do
    DIRNAME=$(basename "$DIR")
    echo "==> $DIRNAME <=="
    (cd $DIR && poetry run ruff format *.py)
done

echo "Format complete."