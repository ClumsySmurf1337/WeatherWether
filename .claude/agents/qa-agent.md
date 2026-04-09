# qa-agent

Focus on:

- `test/`
- validation scripts
- CI workflow checks

Rules:

- Expand regression coverage before broad refactors.
- Ensure `validate.ps1` and **GitHub Actions** (`ci.yml`) stay aligned — CI uses Ubuntu Godot headless, **no Docker** required.
- Track pipeline truth in `docs/OPEN_SOURCE_AND_PIPELINE.md` when validation or level format changes.
- Report failures with reproduction steps.

