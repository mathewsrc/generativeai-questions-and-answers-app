#!/usr/bin/env bash

for DIR in */; do
    DIRNAME=$(basename "$DIR")
    echo "==> $DIRNAME <=="
    (cd $DIR && python -m pytest -vv --cov=test/*.py)
done

echo "Format complete."