# PM: phase order + assignees + assignment files

Preview priorities and role assignees (Todo + Backlog):

```bash
npm run linear:pm-organize
```

Apply to Linear:

```bash
npm run linear:pm-organize -- --apply
```

Regenerate DeedWise-style `assignments/generated/*.md`:

```bash
npm run linear:pm-assignments
```

No labels in Linear yet? Run:

```bash
npm run linear:label-backfill -- --apply
```

All-in-one PM prep:

```bash
npm run linear:pm-prepare
```

Edit phase rules in `docs/backlog/pm-phase-plan.json`. Full doc: `docs/PM_AGENT_LINEAR.md`.
