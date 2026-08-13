# changelog-drafter

> **Tier L1 — Read-only** | Runs once per day | Low cost

Collects all pull requests merged since the last git tag and drafts a release notes entry in [keep-a-changelog](https://keepachangelog.com) format. It writes the draft to `report.md` for a human to review and edit before publishing. It never commits, tags, or pushes anything.

---

## What Problem Does This Solve?

Writing release notes by hand means reviewing every PR that merged since the last release — tedious, error-prone, and often skipped entirely. This loop does that review automatically every day so your changelog is always one edit away from being published.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L1 — read-only, zero mutations |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 20,000 |
| **Max wall time** | 3 minutes (180 seconds) |
| **Resumable** | No |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Finds the latest git tag: `git describe --tags --abbrev=0`
2. Lists all PRs merged after that tag: `gh pr list --state merged --search "merged:>DATE"`
3. Groups the PRs into changelog sections:
   - **Added** — new features
   - **Changed** — behaviour changes
   - **Fixed** — bug fixes
   - **Deprecated** — things being phased out
   - **Removed** — deleted features
   - **Security** — vulnerability fixes
4. Writes a draft `CHANGELOG` entry to `loops/changelog-drafter/report.md`
5. Stops — nothing is committed or pushed

---

## What It Will NEVER Do

```
✗ Commit changes
✗ Push to any branch
✗ Create or move a git tag
✗ Open a pull request
✗ Modify CHANGELOG.md directly
```

---

## Output

After each run, `loops/changelog-drafter/report.md` contains a draft like:

```markdown
## [Unreleased] — 2026-08-14

### Added
- feat: add `memory inject` command (#201)
- feat: support Pi Coding Agent profile (#198)

### Fixed
- fix: `doctor` command exits 1 on missing optional tool (#195)

### Changed
- chore: bump V runtime to 0.4.9 (#199)
```

Copy this into your `CHANGELOG.md`, replace `[Unreleased]` with the version number, and you're done.

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`)
- At least one git tag in the repository (the loop uses the latest tag as its starting point)
- Read access to pull requests

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run changelog-drafter
```

---

## Safety Contract

```yaml
allowlist: []     # read-only
deny:
  - merge
  - push
  - commit
  - tag
```
