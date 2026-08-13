# oss-triage

> **Tier L1 — Read-only / Propose-only** | Runs once per day | Medium cost | Resumable

Scans open issues across a multi-repository open-source software (OSS) ecosystem. It identifies issues needing attention, applies labels, and posts helpful comments (such as answering simple questions or asking for missing reproduction steps). Any complex triage items are logged in a report.

---

## What Problem Does This Solve?

Managing issues across 20–50 repositories is overwhelming. Simple questions sit unanswered, and bug reports frequently lack reproducer code, which slows down development. This loop acts as a triage assistant: answering the easy questions, requesting information on incomplete bug reports, and applying labels so maintainers can focus on solving triaged problems.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L1 — Read-only / Propose-only (Limited mutations allowed for label/comment) |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 150,000 |
| **Max runs / day** | 1 |
| **Max wall time** | 20 minutes (1200 seconds) |
| **Resumable** | Yes — uses `STATE.md` checkpoints |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Reads `loops/oss-triage/STATE.md` to resume from the last processed repository if interrupted.
2. For each configured repository:
   - Scans open issues where the last comment is **not** from a maintainer.
   - Evaluates the issue:
     - **Obvious question with no response** → Drafts and posts a response comment.
     - **Issue with no labels** → Applies appropriate taxonomy labels (e.g., `bug`, `documentation`).
     - **Bug with no reproduction steps** → Comments requesting a minimal reproducer.
     - **Security report detected** → Immediately raises a `human_escalation` exit.
3. Saves a checkpoint to `STATE.md` after each repository.
4. Writes a detailed summary to `loops/oss-triage/report.md` showing actions taken and pending items.

---

## Permitted Actions (Allowlist)

```
✓ label     — Apply labels to issues
✓ comment   — Post comments seeking details or answering questions
✓ assign    — Assign issues to relevant contributors
```

## What It Will NEVER Do

```
✗ Close any issue
✗ Merge any code
✗ Approve pull requests
✗ Force-push to any branch
```

---

## Output

Writes a daily report to `loops/oss-triage/report.md` detailing all activities:

```markdown
## OSS Triage Report — 2026-08-14

### Actions Taken
- **org/repo-a #102**: Applied `bug` label.
- **org/repo-a #105**: Commented requesting a reproduction repository.
- **org/repo-b #44**: Answered setup question regarding config options.

### Pending Items (Needs Maintainer Review)
- **org/repo-a #99**: Complex feature request proposing structural API changes.
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated with issue write permissions (`gh auth login`).
- Repo read/write access for the targeted repositories.

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run oss-triage
```

---

## Safety Contract

```yaml
tier: L1
allowlist:
  - label
  - comment
  - assign
deny:
  - merge
  - close
  - push
  - approve
  - force-push
```
