# post-merge-cleanup

> **Tier L2 — Controlled writes** | Runs every 6 hours | Low cost

Performs off-peak housekeeping tasks on the repository. It scans for git branches that have already been merged into `main` and deletes them. It also closes issues resolved by merged PRs and flags stale issues that have seen no activity for over 90 days.

---

## What Problem Does This Solve?

Over time, active repositories build up hundreds of merged feature branches and abandoned issues, cluttering git histories, PR interfaces, and project boards. Doing this cleanup by hand is tedious. This loop automates branch deletions, updates issue states, and keeps the tracker tidy.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L2 — limited write access |
| **Cadence** | `6h` — every 6 hours |
| **Max tokens / run** | 20,000 |
| **Max runs / day** | 4 |
| **Max wall time** | 5 minutes (300 seconds) |
| **Resumable** | No |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Lists remote branches merged into main: `git branch -r --merged main`
2. Deletes remote branches merged **more than 7 days ago** (skips protected branches like `main`, `develop`, and release branches `release/*`).
3. Lists issues linked to merged PRs that are still open, and closes them.
4. Identifies issues with no activity for **90+ days** and posts a gentle status query comment (does **not** close the issue).
5. Writes a summary of actions to `loops/post-merge-cleanup/plan.md`.

---

## Permitted Actions (Allowlist)

```
✓ delete_merged_branch  — Delete remote git branches merged > 7 days ago
✓ close_stale_issue     — Close issues resolved by merged PRs
✓ comment               — Post stale warning messages
```

## What It Will NEVER Do

```
✗ Merge any PR
✗ Approve any PR
✗ Delete unmerged branches
✗ Close active issues
✗ Force-push to main or update git tags
```

---

## Output

Writes a cleanup summary to `loops/post-merge-cleanup/plan.md`:

```markdown
## Post-Merge Cleanup — 2026-08-14T12:00Z

### Deleted Branches
- `origin/feat/auth-login` (merged 9 days ago)
- `origin/fix/docs-broken-link` (merged 7 days ago)

### Closed Issues
- **Issue #88** (Resolved by PR #92)

### Stale Warnings Posted
- **Issue #12** (No activity for 95 days)
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated with write/delete permissions (`gh auth login`).
- Local git clone access to query branches.

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run post-merge-cleanup
```

---

## Safety Contract

```yaml
tier: L2
allowlist:
  - delete_merged_branch
  - close_stale_issue
  - comment
deny:
  - merge
  - approve
  - delete-unmerged-branch
  - close-active-issue
```
