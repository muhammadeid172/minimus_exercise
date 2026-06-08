# Submission Notes

## Assumptions

- The host system is Linux (x86_64 or ARM64 recommended).
- Go, Melange, and apko are installed.
- Docker is installed and running for runtime tests.
- All commands are executed from inside the `solution/` directory.

---

## How to Run

1. Open a terminal in the `solution/` directory.

2. Make the test scripts executable:

```bash
chmod +x tests/test.sh
chmod +x tests/test-vulnerable.sh
```

3. Run the patched build and tests:

```bash
./tests/test.sh
```

4. Run the unpatched build and tests:

```bash
./tests/test-vulnerable.sh
```

The tests demonstrate runtime behavior using both normal and malicious YAML inputs, using both patched and unpatched packages.

---

## Things I would improve with more time

All commands and tests were executed on a Linux ARM64 (aarch64) environment, and they passed as expected.

With more time and resources, I would also test the solution on additional common architectures such as x86_64/amd64 and ARMv7 to verify portability and ensure consistent behavior across environments. This could likely be done locally using QEMU/container-based emulation tools such as Docker Buildx.


---

Full implementation details and additional notes are available in `../README.md`.
