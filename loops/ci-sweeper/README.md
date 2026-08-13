# ci-sweeper

> **Tier L2 — Controlled writes** | Runs every 15 minutes | Very high cost

Monitors CI runs across open PRs and the main branch. When it finds a failing CI run, it diagnoses the root cause, attempts a minimal fix (under 20 lines), and opens a **draft PR** with the proposed fix. If the fix is too complex or uncertain, it posts a diagnostic comment instead. It never auto-merges and never force-pushes.

---

## What Problem Does This Solve?

A failing CI run blocks every contributor working on the repository. Finding the failure, reading the logs, and writing a fix takes time — especially if it is a flaky test, a lockfile issue, or a missing environment variable. This loop catches those failures within 15 minutes and proposes fixes so the team can unblock quickly.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L2 — limited write access |
| **Cadence** | `15m` — every 15 minutes |
| **Max tokens / run** | 100,000 |
| **Max runs / day** | 48 |
| **Max wall time** | 15 minutes (900 seconds) |
| **Max iterations** | 3 |
| **Resumable** | No |
| **Verifier** | `agent-toolkit-code-reviewer` |

> ⚠️ **This loop is expensive.** It runs 48 times per day with a 100k token budget. Start at L1 observation for at least 3 days before enabling this loop on a production repository. The default budget is intentionally conservative.

---

## What It Does — Step by Step

1. Lists failing CI runs: `gh run list --status failure`
2. For each failing run (max 2 per execution):
   - Fetches full logs: `gh run view --log`
   - Identifies the root cause
   - If the fix is **straightforward** (< 20 lines, no architectural impact):
     - Creates a worktree
     - Applies the fix
     - Opens a **draft PR** with a clear description of what failed and why
   - If the fix is **complex or uncertain**:
     - Posts a diagnostic comment on the relevant PR or commit — no code changes
3. Writes `plan.md` summarising: failures found, fixes attempted, draft PRs opened

---

## Permitted Actions (Allowlist)

```
✓ comment           — post diagnostic comments on PRs/commits
✓ create_draft_pr   — open a draft PR with a proposed fix
```

## What It Will NEVER Do

```
✗ Merge any PR
✗ Approve any PR
✗ Close any PR or issue
✗ Force-push to any branch
✗ Delete any branch
✗ Push directly to main
```

---

## Output

After each run, `loops/ci-sweeper/plan.md` is written with:

```markdown
## CI Sweeper — 2026-08-14T08:15Z

### Failures Found
| Run ID | Branch | Failure | Root Cause |
|--------|--------|---------|------------|
| #4821 | feat/login | test_auth failed | Missing env var AUTH_SECRET |

### Actions Taken
| PR | Action | Outcome |
|----|--------|---------|
| #draft-1 | Opened draft PR with fix | Added AUTH_SECRET to test env |

### Skipped (too complex)
- Run #4818 on main: compile error in new V module — requires architectural review
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`)
- Write access to open draft PRs in the repository
- CI must be configured (GitHub Actions, or another system visible via `gh run list`)

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run ci-sweeper
```

---

## Graduated Deployment

> Never deploy this loop at L2 immediately.

1. **Observe first:** Comment out the `create_draft_pr` action and run at L1 for 3 days. Confirm the diagnostic comments are accurate.
2. **Enable writes:** Re-enable `create_draft_pr`. Monitor the first 5 draft PRs manually before trusting the loop fully.
3. **Adjust budget:** If the loop consistently finishes in 2 iterations, lower `max_iterations` from 3 to 2 to save tokens.

---

## Safety Contract

```yaml
tier: L2
allowlist:
  - comment
  - create_draft_pr
deny:
  - merge
  - approve
  - close
  - force-push
  - delete-branch
```
