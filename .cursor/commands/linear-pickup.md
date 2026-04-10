# Linear Resume/Pickup by Role

Dry-run:

```powershell
npm run linear:resume-pickup -- --role=gameplay-programmer
```

Claim issue:

```powershell
npm run linear:resume-pickup -- --role=gameplay-programmer --apply
```

`linear:resume-pickup` checks **In Progress first** for your role (resume where you left off), then claims from Todo only when nothing is in progress.
