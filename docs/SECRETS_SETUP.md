# Secrets Setup

Create `.env` from `.env.example` and set required tokens.

## Required

- `LINEAR_API_KEY`
- `LINEAR_TEAM_ID`

## Optional

- `GITHUB_TOKEN`

## Notes

- Never commit `.env`.
- Use token scopes minimally required for automation.
- Prefer per-machine user secrets in CI/CD where possible.

