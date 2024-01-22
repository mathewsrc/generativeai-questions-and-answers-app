#!/bin/bash

for DIR in */; do
    DIRNAME=$(basename "$DIR")
    echo "==> $DIRNAME <=="
    (cd $DIR && poetry run ruff check . --fix)
done

echo "Format complete."