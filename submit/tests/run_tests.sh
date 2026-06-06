#!/bin/bash
set -e

echo "=== Detecting host architecture ==="
HOSTARCH=$(uname -m)

case "$HOSTARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  armv7*) ARCH=arm ;;
  i386 | i686) ARCH=386 ;;
  *) echo "Unsupported architecture: $HOSTARCH"; exit 1 ;;
esac

echo "Detected architecture: $ARCH"

echo "=== Cleaning old packages ==="
rm -rf packages

echo "=== Building Melange package ==="
melange keygen
melange build --arch $ARCH --signing-key melange.rsa melange/dasel.yaml

echo "=== Testing Melange package ==="
melange test --arch $ARCH melange/dasel.yaml

echo "=== Building apko container image ==="
apko build --arch $ARCH apko/dasel.yaml dasel ./dasel-image-$ARCH.tar

echo "=== Loading Docker image ==="
docker load -i ./dasel-image-$ARCH.tar

echo "=== Running version command inside container ==="
docker run --rm dasel:latest-$ARCH version

echo "=== Running normal YAML test inside container ==="
cat tests/normal.yaml | docker run --rm -i dasel:latest-$ARCH query --in yaml

echo "=== Running malicious YAML test inside container ==="
cat tests/malicious.yaml | docker run --rm -i dasel:latest-$ARCH query --in yaml

echo "All tests completed successfully."