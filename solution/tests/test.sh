#!/bin/bash
set -e

SHOW_OUTPUT=false
if [ "$1" = "--show-output" ]; then
  SHOW_OUTPUT=true
fi

echo "=== Detecting host architecture ==="
HOSTARCH=$(uname -m)

case "$HOSTARCH" in
x86_64) ARCH=amd64 ;;
aarch64 | arm64) ARCH=arm64 ;;
armv7*) ARCH=arm ;;
i386 | i686) ARCH=386 ;;
*)
  echo "Unsupported architecture: $HOSTARCH"
  exit 1
  ;;
esac

echo "Detected architecture: $ARCH"

echo "=== Cleaning old packages ==="
rm -rf ./build
mkdir -p build
cd ./build

echo "=== Building Melange package ==="
melange keygen
melange build --arch $ARCH --signing-key melange.rsa ../melange/dasel.yaml

echo "=== Testing Melange package ==="
melange test --arch $ARCH ../melange/dasel.yaml

echo "=== Building apko container image ==="
apko build --arch $ARCH ../apko/dasel.yaml dasel ./dasel-image-$ARCH.tar

echo "=== Loading Docker image ==="
docker load -i ./dasel-image-$ARCH.tar

echo "=== Running version command inside container ==="
VERSION=$(docker run --rm dasel:latest-$ARCH version)
if [ "$SHOW_OUTPUT" = true ]; then
  echo "Version: $VERSION"
fi
if [[ "$VERSION" == *"v3.3.1"* ]]; then
  echo "PASS: Package is based on dasel version 3.3.1"
else
  echo "FAIL: Package is not based on dasel version 3.3.1"
  exit 1
fi

echo "=== Running normal YAML test inside container ==="
NOR_RESULT=$(docker run --rm -i -e USER=nonroot dasel:latest-$ARCH query --in yaml <../tests/normal.yaml 2>&1)
if [ "$SHOW_OUTPUT" = true ]; then
  echo "Normal yaml parsing result:"
  echo "$NOR_RESULT"
fi

if diff -u ../tests/normal-expected.yaml <(echo "$NOR_RESULT"); then
  echo "PASS: Normal YAML parsed as expected."
else
  echo "FAIL: Failed to parse normal YAML."
  exit 1
fi

echo "=== Running malicious YAML test inside container ==="
set +e
MAL_RESULT=$(docker run --rm -i -e USER=nonroot dasel:latest-$ARCH query --in yaml <../tests/malicious.yaml 2>&1)
STATUS=$?
set -e

if [ "$SHOW_OUTPUT" = true ]; then
  echo "Malicious yaml parsing result:"
  echo "$MAL_RESULT"
fi

if [ "$STATUS" -eq 0 ]; then
  echo "FAIL: Malicious YAML unexpectedly accepted. Expected \`yaml expansion depth exceeded\` or \`yaml expansion budget exceeded\` error."
  exit 1
fi

EXPECTED_ERRORS=(
  "yaml expansion depth exceeded"
  "yaml expansion budget exceeded"
)

if [[ "$MAL_RESULT" == *"yaml expansion depth exceeded"* || "$MAL_RESULT" == *"yaml expansion budget exceeded"* ]]; then
  echo "PASS: Malicious YAML triggered protected rejection as expected."
else
  echo "FAIL: Malicious YAML rejected, but for unexpected reason."
  echo "Error should contain \`yaml expansion depth exceeded\` or \`yaml expansion budget exceeded\`"
  exit 1
fi

cd ..
echo "All tests completed successfully."
