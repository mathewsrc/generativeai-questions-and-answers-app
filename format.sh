#!/bin/bash

for DIR in */; do
    DIRNAME=$(basename "$DIR")
    echo "==> $DIRNAME <=="
    (cd $DIR && poetry run ruff format .)
done

echo "Format complete."