# Dasel v3.3.1 patch Packaging and Testing
This is an exercise as part of the hiring process at Minimus

## Overview
This repository contains the build and test setup for `dasel v3.3.1`, including a security fix for **CVE-2026-33320** (unbounded YAML alias expansion). The solution uses **Melange** to package the binary and **apko** to build a Docker image containing the package.

---

## Directory Structure

```
root/
├── README.md
├── exercise.pdf
└── submit/
    ├── melange/
    │   ├── dasel.yaml              # Melange package configuration
    │   └── CVE-2026-33320.patch    # Patch applied to Dasel source
    ├── apko/
    │   └── dasel.yaml              # apko image configuration
    └── tests/
        ├── normal.yaml             # Safe YAML test case
        ├── malicious.yaml          # Recursive YAML aliases (malicious) test case
        └── test.sh            # Test script for automated build/test
```

---

## Prerequisites

- Linux host (x86_64, arm64/aarch64, armv7, or i386)  
- Docker  
- Go  
- Melange  
- apko  

The `test.sh` script automatically detects the host architecture.

---

## Building and Testing

1. Open a terminal in the `submit/` directory.
2. Make the test script executable:

```bash
chmod +x tests/test.sh
```

3. Run the script:

```bash
./tests/test.sh
```

The script will:

- Detect host architecture automatically.
- Clean old package directories.
- Build the Dasel package with Melange (including the CVE patch).
- Build the Docker image with apko.
- Load the Docker image locally.
- Run tests inside the container:
  - Normal YAML is parsed successfully.
  - Malicious YAML is safely rejected (`yaml expansion depth exceeded`).
  - Dasel version command is verified.

---

## Runtime Tests

### Normal YAML Test

Verifies that Dasel can correctly parse and output valid YAML content.

### Malicious YAML Test

Uses recursive YAML aliases to simulate malicious input. Expected behavior:

```
yaml expansion depth exceeded
```

This demonstrates that the CVE fix is active and prevents unbounded alias expansion.

---

## Notes

- The Dasel package is built from the v3.3.1 source code.
- The CVE fix is applied as a patch before compilation.
- Unit tests from the upstream fix were included and executed successfully.
- The Docker image uses the locally built Dasel package.