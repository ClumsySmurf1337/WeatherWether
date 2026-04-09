# Phased backlog (local queue)

Linear **active** issue caps (often **250**) mean bulk imports must be **incremental**.

## How this repo handles it

1. **Templates** in `docs/backlog/*.json` + generated outline in `tools/linear/backlog-outline-generator.ts` define the full graph **locally** (unbounded).
2. `npm run linear:seed`:
   - **Dedupes** by exact title against all existing team issues.
   - Creates at most **`LINEAR_SEED_BATCH_MAX`** new issues per run (default `40`).
   - Stops when **`LINEAR_ACTIVE_ISSUE_CAP`** non-terminal issues would be exceeded (default `230`).
   - New issues default to **Backlog** state when `LINEAR_STATE_BACKLOG_ID` is set.
3. `npm run linear:promote -- --apply` moves the next batch **Backlog → Todo** without exceeding the cap.

## When a “phase” is done

When a release phase (e.g. Vertical slice) is complete:

- Close or **Done** issues until `linear:status` shows comfortable **headroom**.
- Run `npm run linear:seed` again to pull the next chunk from the local template set.
- Then `npm run linear:promote -- --apply` + `npm run linear:producer -- --apply`.

No separate phase JSON is required — the template list is deterministic; **title dedupe** prevents duplicates across reruns.
