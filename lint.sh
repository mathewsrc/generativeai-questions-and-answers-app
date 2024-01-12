#!/usr/bin/env bash

for DIR in */; do
    DIRNAME=$(basename "$DIR")
    echo "==> $DIRNAME <=="
    (cd $DIR && poetry run ruff check *.py)
done

echo "Format complete."