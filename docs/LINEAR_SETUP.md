# Linear Setup

## Prerequisites

- Linear workspace and team created.
- API key generated.
- `.env` contains:
  - `LINEAR_API_KEY`
  - `LINEAR_TEAM_ID`

## Install Dependencies

```powershell
npm install
```

## Dry Run

```powershell
npm run linear:seed -- --dry-run
```

## Create Backlog

```powershell
npm run linear:seed
```

## Daily Standup Summary

```powershell
npm run linear:standup
```

## Notes

- Backlog templates are in `docs/backlog/*.json`.
- The seeding script is idempotent by convention only; reruns can create duplicates.
- For production reruns, use filtered title checks or explicit issue IDs in a future hardening pass.

