# GitHub auto-merge (optional, opinionated)

Fully unsupervised merge is risky (game builds, asset PRs, surprise conflicts). Recommended pattern:

## Safe pattern

1. **Branch protection** on `main`: require PR, require status **Whether CI**, require up-to-date.
2. Enable **Allow auto-merge** in repo settings.
3. Authors (or PM agent) click **Enable auto-merge** on the PR, or add label `automerge` only after self-review.

## What this repo does not do by default

- No always-on workflow that merges **every** PR without labels and without human review.

## If you want automation

Add a workflow that:

- Triggers on `pull_request` (labeled `automerge`) **after** `Whether CI` is green, using `workflow_run` or a merge queue.

Use a **PAT** with `repo` scope if `GITHUB_TOKEN` permissions are insufficient for your org rules.

## Copilot / agent PRs

Require each agent PR to:

- Link `WEA-###` in title or body.
- Pass `tools/tasks/validate.ps1` locally when Godot logic changes.
