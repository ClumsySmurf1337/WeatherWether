# Secure Signing Future Strategy

## Goal

Prepare secure iOS signing operations without enabling them during Windows/Steam-first phase.

## Requirements

- Certificate and provisioning profiles stored in secure secret manager.
- No signing material committed to repository.
- Build job decrypts material at runtime only.
- Rotate certificates on schedule.

## Operational Controls

- Restrict signing job to protected branches/tags.
- Require manual approval for release workflow.
- Audit signing job logs for secret redaction.

