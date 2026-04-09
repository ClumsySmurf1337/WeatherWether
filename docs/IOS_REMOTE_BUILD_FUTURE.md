# iOS Remote Build Future Plan

This document defines the deferred iOS lane while Windows/Steam remains the current shipping priority.

## Why Remote macOS

iOS builds and signing require macOS + Xcode. A remote macOS provider can host this pipeline once needed.

## Candidate

- AWS EC2 Mac instances for remote build and signing workers.

## Future Activation Checklist

- Provision remote macOS host.
- Install Xcode and required command-line tooling.
- Configure secure signing credentials.
- Enable `tools/ci/templates/ios-remote-mac.yml`.
- Add manual approval gate before release jobs.

