# pr-babysitter

> **Tier L2 — Controlled writes** | Runs every 15 minutes | High cost

Monitors open pull requests on the repository. It scans for PRs that have received no activity or reviews for over an hour, performs a comprehensive diff analysis on the code changes, and posts constructive review comments directly to the PR. It never merges or approves PRs.

---

## What Problem Does This Solve?

Pull requests frequently sit waiting for reviews, blocking contributors and slowing down code integration. Maintainers can easily miss updates or get sidetracked. This loop acts as a "babysitter" for open PRs — providing immediate, constructive code analysis and feedback within minutes so contributors aren't left waiting.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L2 — limited write access |
| **Cadence** | `15m` — every 15 minutes |
| **Max tokens / run** | 80,000 |
| **Max runs / day** | 96 |
| **Max wall time** | 10 minutes (600 seconds) |
| **Resumable** | No |
| **Verifier** | `agent-toolkit-code-reviewer` |

> ⚠️ **This loop is active.** It runs every 15 minutes. Ensure the token budget matches your repository's PR volume to avoid running up excessive LLM API costs.

---

## What It Does — Step by Step

1. Lists all open pull requests: `gh pr list`
2. For each PR that has received **no review in the last 60 minutes**:
   - Reads the code diff: `gh pr diff`
   - Analyzes the changes for issues, style violations, and correctness.
   - Posts a constructive review comment containing:
     - A brief summary of the changes.
     - 1–3 specific, actionable suggestions.
     - Any identified blockers or bugs.
3. If a potential security vulnerability is detected, it raises a `human_escalation` exit.
4. Writes a summary of reviews posted to `loops/pr-babysitter/plan.md`.

---

## Permitted Actions (Allowlist)

```
✓ comment   — Post code review comments on PRs
```

## What It Will NEVER Do

```
✗ Merge any PR
✗ Approve any PR
✗ Close any PR or issue
✗ Push code to any branch
✗ Label PRs
```

---

## Output

Writes a plan log to `loops/pr-babysitter/plan.md`:

```markdown
## PR Babysitter — 2026-08-14T10:15Z

### Reviews Posted
| PR # | Title | Author | Comments Posted |
|------|-------|--------|-----------------|
| #112 | fix: secure session cookies | dev-user | Highlighted cookie attributes recommendation |
| #114 | docs: update installer guide | doc-writer | Suggested correction to bash command syntax |

### Escalated
- **PR #115**: Flagged potential SQL Injection vector; escalated for human review.
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated with review comment permissions (`gh auth login`).
- Repo read/write access.

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run pr-babysitter
```

---

## Safety Contract

```yaml
tier: L2
allowlist:
  - comment
deny:
  - merge
  - approve
  - close
  - push
  - label
```
