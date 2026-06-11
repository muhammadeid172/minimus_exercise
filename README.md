# Dasel CVE-2026-33320 vulnerability patch: Packaging and Testing

This is an exercise as part of the hiring process at Minimus.

Summarized build and run instructions can be found in `solution/NOTES.md`.

## Overview

This repository contains the build and test setup for `dasel v3.3.1`, including a security fix for **CVE-2026-33320** (unbounded YAML alias expansion). The solution uses **Melange** to package the binary and **apko** to build a Docker image containing the package.

Additionally, an **unpatched build** is included to visualize the difference between patched and unpatched behavior.

---

## Directory Structure

```
root/
├── README.md
├── exercise.pdf
└── solution/
    ├── melange/
    │   ├── dasel.yaml              # Melange package configuration (patched)
    │   ├── dasel-vulnerable.yaml   # Melange package configuration (unpatched)
    │   └── CVE-2026-33320.patch    # Patch applied to Dasel source
    ├── apko/
    │   └── dasel.yaml              # apko image configuration
    └── tests/
        ├── normal.yaml             # Safe YAML test case
        ├── normal-expected.yaml    # Expected output for normal YAML test
        ├── malicious.yaml          # Recursive YAML aliases (malicious) test case
        ├── test.sh                 # Test script for patched build
        └── test-vulnerable.sh      # Test script for unpatched build
```

---

## Prerequisites and Assumptions

- The host system is Linux (x86_64 or ARM64 recommended).
- Go, Melange, and apko are installed.
- Docker is installed and running for runtime tests.

The test scripts automatically detect the host architecture.

## Building and Testing

### Patched Packet - Building and Tesing

#### 1. Open a terminal in the `solution/` directory.

#### 2. Detect architecture

```bash
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
```

#### 3. Prepare build directory

```bash
rm -rf ./build
mkdir -p build
cd ./build
```

#### 4. Generate signing key

```bash
melange keygen
```

#### 5. Build the patched Melange package

```bash
melange build --arch $ARCH --signing-key melange.rsa ../melange/dasel.yaml
```

#### 6. Test the Melange package

```bash
melange test --arch $ARCH ../melange/dasel.yaml
```

#### 7. Build the apko image

```bash
apko build --arch $ARCH ../apko/dasel.yaml dasel ./dasel-image-$ARCH.tar
```

#### 8. Load the Docker image

```bash
docker load -i ./dasel-image-$ARCH.tar
```

#### 9. Runtime tests

Version check:

```bash
docker run --rm dasel:latest-$ARCH version
```

Normal YAML test:

```bash
docker run --rm -i -e USER=nonroot dasel:latest-$ARCH query --in yaml <../tests/normal.yaml
```

Expected patched behavior:

```text
The successfully parsed content.
```

Malicious YAML test:

```bash
docker run --rm -i -e USER=nonroot dasel:latest-$ARCH query --in yaml <../tests/malicious.yaml
```

Expected patched behavior:

```text
Possitive failure: `yaml expansion depth exceeded` or `yaml expansion budget exceeded` error.
```

### Unpatched Packet - Building and Tesing

#### 1-4. Run commands 1 to 4 from the last section (Go back to `./solution`)

#### 5. Build the patched Melange package

```bash
melange build --arch $ARCH --signing-key melange.rsa ../melange/dasel-vulnerable.yaml
```

#### 6. Test the Melange package

```bash
melange test --arch $ARCH ../melange/dasel-vulnerable.yaml
```

#### 7-9. Run commands 7 to 9 from the last section

Expected unpatched behavior:

```text
For the normal yaml sample: the successfully parsed content, same as before.
For the malocious yaml sample: security failure, stack overflow or similar.
```

### Automated Test Scripts

#### 1. Open a terminal in the `solution/` directory.

#### 2. Run the patched build and tests:

```bash
chmod +x tests/test.sh
./tests/test.sh
```

(Optional) Print runtime command outputs during the patched tests:

```bash
./tests/test.sh --show-output
```

#### 3. Run the unpatched build and tests (for verification only):

```bash
chmod +x tests/test-vulnerable.sh
./tests/test-vulnerable.sh
```

(Optional) Print runtime command outputs during the unpatched tests:

```bash
./tests/test-vulnerable.sh --show-output
```

Scripts description:

- Detects host architecture automatically.
- Cleans old build files.
- Builds the Dasel package with Melange
  - `./tests/test.sh`: using `./melange/dasel.yaml` (patch applied).
  - `./tests/test-vulnerable.sh`: using `./melange/dasel-vulneravle.yaml` (patch not applied).
- Runs Melange package tests.
- Builds the Docker image with apko.
- Loads the Docker image locally.
- Runs runtime tests inside the container:
  - `./tests/test.sh` & `./tests/test-vulnerable.sh`:
    - Verify dasel version is `3.1.1`.
    - Print normal YAML file parsing.
    - Compare actual output with expected output.
  - `./tests/test.sh`:
    - Print malicious YAML file prasing error.
    - Verify malicious YAML file is safely rejected and error contains `yaml expansion depth exceeded` or `yaml expansion budget exceeded` error.
  - `./tests/test-vulnerable.sh`:
    - Print malicious YAML file prasing error.
    - Verify malicious YAML file parsing fails.
      - We could check if the output contains "stack overflow" or "goroutine stack exceeds", but we decided not to depend on runtime errors that are not part of our source code. The error is printed to the std for visual/manual check.

> The unpatched melange yaml is included for comparison and demonstration purposes only, and is not intended for production use.
> This allows us to **visualize the difference** between the patched and unpatched versions.

## Runtime Test Samples

### Normal YAML Test

Verifies that Dasel can correctly parse and output valid YAML content.

### Malicious YAML Test

Uses recursive YAML aliases to simulate malicious input. Expected behavior:

- **Patched:** safe rejection with `yaml expansion depth exceeded` or `yaml expansion budget exceeded` error.
- **Unpatched:** may crash or hang due to unbounded alias expansion.

## Notes

- The Dasel package is built from v3.3.1 source code.
- The CVE fix is applied as a patch before compilation in `melange/dasel.yaml`.
- Unit tests from the upstream fix were included and executed successfully.
- Both patched and unpatched Docker images can be built locally.
- SBOM, RSA keys, and build artifacts are generated in the `build/` directory.
- Test scripts (`test.sh` and `test-vulnerable.sh`) are fully automated and detect host architecture.
