# Dasel CVE-2026-33320 vulnerability patch: Packaging and Testing

This is an exercise as part of the hiring process at Minimus

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

### Patched Build

1. Open a terminal in the `solution/` directory.
2. Make the test script executable:

```bash
chmod +x tests/test.sh
```

3. Run the script:

```bash
./tests/test.sh
```

Script description:

- Detects host architecture automatically.
- Cleans old build files.
- Builds the Dasel package with Melange (including the CVE patch).
- Builds the Docker image with apko.
- Loads the Docker image locally.
- Runs tests inside the container:
  - Dasel version command is verified.
  - Normal YAML file parses correctly.
  - Malicious YAML file is safely rejected (`yaml expansion depth exceeded`).

### Unpatched Build

1. Open a terminal in the `solution/` directory.
2. Make the unpatched test executable:

```bash
chmod +x tests/test-vulnerable.sh
```

3. Run the script:

```bash
./tests/test-vulnerable.sh
```

Script description:

- This script performs the same steps as the previous script, except that it uses `dasel-vulnerable.yaml`, which does not apply the CVE-2026-33320 patch.
- Run the same tests inside the container:
  - Dasel version command is verified.
  - Normal YAML file parses correctly.
  - Malicious YAML file causes stack overflow runtime error, demonstrating vulnerability.

> This allows us to **visualize the difference** between the patched and unpatched versions.

## Runtime Tests

### Normal YAML Test

Verifies that Dasel can correctly parse and output valid YAML content.

### Malicious YAML Test

Uses recursive YAML aliases to simulate malicious input. Expected behavior:

- **Patched:** `yaml expansion depth exceeded`  
- **Unpatched:** may crash or hang due to unbounded alias expansion.

## Notes

- The Dasel package is built from v3.3.1 source code.
- The CVE fix is applied as a patch before compilation in `melange/dasel.yaml`.
- Unit tests from the upstream fix were included and executed successfully.
- Both patched and unpatched Docker images can be built locally.
- SBOM, RSA keys, and build artifacts are generated in the `build/` directory.
- Test scripts (`test.sh` and `test-vulnerable.sh`) are fully automated and detect host architecture.