# daily-triage

> **Tier L1 — Read-only** | Runs once per day | Low cost

Scans every new GitHub issue opened in the last 24 hours and proposes labels, priority scores, and a brief summary for each one. It writes these proposals to `report.md` for a human maintainer to review. It never touches the repository — no labels applied, no comments posted, nothing changed.

---

## What Problem Does This Solve?

On active repositories, new issues pile up quickly. Without triage, issues go unlabeled for days, making it impossible to filter, prioritize, or search them. This loop watches for new issues every day so nothing falls through the cracks.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L1 — read-only, zero mutations |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 30,000 |
| **Max wall time** | 5 minutes (300 seconds) |
| **Resumable** | No |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Lists all open issues created in the last 24 hours using `gh issue list`
2. For each issue, reads the title and body
3. Proposes:
   - **Priority** — `critical` / `high` / `medium` / `low`
   - **Labels** — based on the issue content and the repo's existing label taxonomy
   - **Summary** — 1–2 sentence description of the issue
4. Writes all proposals to `loops/daily-triage/report.md`
5. Stops — does not apply anything

---

## What It Will NEVER Do

```
✗ Apply labels
✗ Post comments on issues
✗ Close or merge anything
✗ Push code
✗ Take any action that modifies the repository
```

---

## Output

After each run, `loops/daily-triage/report.md` is written with a table similar to:

```markdown
## Daily Triage Report — 2026-08-14

| # | Title | Proposed Labels | Priority | Summary |
|---|-------|----------------|----------|---------|
| #42 | Login fails on mobile | bug, ux | high | Users cannot log in on iOS Safari due to a cookie scope issue. |
| #43 | Add dark mode | enhancement | low | Feature request to add a dark mode toggle to the settings page. |
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`)
- Read access to the repository's issues

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run daily-triage

# Initialise for a specific repo
./bin/loop init daily-triage --repo owner/repo
./bin/loop run daily-triage
```

---

## When to Upgrade to L2

Once you have reviewed 3+ consecutive reports and confirmed the proposed labels are accurate, you can upgrade to an L2 version of this loop that applies labels directly. The L2 version would move `label` from the `deny` list to the `allowlist`.

> **Start here. Run it clean for at least 3 days before applying labels automatically.**

---

## Safety Contract

This loop is **L1**. The loop runner enforces that the actions listed in `deny` are never executed, regardless of what the agent decides. Even if the LLM reasons that it should apply a label, the runner blocks it.

```yaml
allowlist: []       # nothing permitted beyond reading
deny:
  - merge
  - close
  - label
  - comment
  - push
```
