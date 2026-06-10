#!/bin/bash
set -e

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
docker run --rm dasel:latest-$ARCH version

echo "=== Running normal YAML test inside container ==="
NOR_RESULT=$(docker run --rm -i -e USER=nonroot dasel:latest-$ARCH query --in yaml <../tests/normal.yaml 2>&1)
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

ERROR_MSG="FAIL: Malicious YAML unexpectedly accepted. Expected \`yaml expansion depth exceeded\` or \`yaml expansion budget exceeded\` error."
if [ "$STATUS" -eq 0 ]; then
  echo "$ERROR_MSG"
  exit 1
fi

EXPECTED_ERRORS=(
  "yaml expansion depth exceeded"
  "yaml expansion budget exceeded"
)

ERROR_FOUND=false
for ERR in "${EXPECTED_ERRORS[@]}"; do
  if [[ "$MAL_RESULT" == *"$ERR"* ]]; then
    ERROR_FOUND=true
    echo "PASS: Malicious YAML triggered protected rejection as expected."
    break
  fi
done

if [ "$ERROR_FOUND" = false ]; then
  echo "$ERROR_MSG"
  echo "Actual output:"
  echo "$MAL_RESULT"
  exit 1
fi

cd ..
echo "All tests completed successfully."
