#!/bin/bash
set -e

echo "=== Cleaning old packages ==="
rm -rf packages

echo "=== Building Melange package (aarch64) ==="
melange build --arch aarch64 --signing-key melange.rsa melange/dasel.yaml

echo "=== Testing Melange package (aarch64) ==="
melange test --arch aarch64 melange/dasel.yaml

echo "=== Building apko container image (aarch64) ==="
apko build --arch aarch64 apko/dasel.yaml dasel:3.3.1-arm64 ./dasel-image.tar

echo "=== Loading Docker image ==="
docker load -i ./dasel-image.tar

echo "=== Running version command inside container ==="
docker run --rm dasel:3.3.1-arm64 version

echo "=== Running normal YAML test inside container ==="
cat tests/normal.yaml | docker run --rm -i dasel:3.3.1-arm64 query --in yaml

echo "=== Running malicious YAML test inside container ==="
cat tests/malicious.yaml | docker run --rm -i dasel:3.3.1-arm64 query --in yaml

echo "All tests completed successfully."
