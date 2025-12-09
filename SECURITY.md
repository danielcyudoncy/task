# # .github/SECURITY.md
## glob Command Injection Vulnerability

### Affected Versions
- glob@10.2.0 to 10.4.9
- glob@11.0.0 to 11.0.3

### Required Actions
1. Update to glob@10.5.0+ or glob@11.1.0+
2. Replace `-c`/`--cmd` with `-g`/`--cmd-arg`
3. Audit build scripts for glob CLI usage
