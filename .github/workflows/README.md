# GitHub Actions In This Repo

This directory contains GitHub Actions workflows that run automatically on pushes and pull requests.

## Trufflehog-OpenSource (trufflehog.yml)

**What it does:** Scans the repository for leaked secrets, API keys, passwords, and other sensitive credentials.

**When it runs:** On every push to `main` and on all pull requests.

**Why we need it:** Infrastructure code often requires credentials, and it's easy to accidentally commit secrets. Trufflehog detects these before they become a security incident. It scans the full git history (`fetch-depth: 0`) to catch secrets that may have been committed and later removed.

**Configuration:** Only reports verified and unknown results (`--results=verified,unknown`), filtering out false positives.