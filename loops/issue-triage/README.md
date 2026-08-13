# issue-triage

> **Tier L1 — Read-only** | Runs every 4 hours | Low cost

Scans unlabeled issues and proposes the appropriate labels, type classification, and priority for each one. Proposals are written to `report.md` for a human to apply. It never touches the repository — no labels applied, no comments posted.

---

## What Problem Does This Solve?

Issues that arrive without labels are invisible to search filters, project boards, and milestone tracking. On active repositories, unlabeled issues pile up within hours. This loop catches them every 4 hours and generates a ready-to-apply labelling proposal so maintainers spend seconds reviewing rather than minutes classifying.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L1 — read-only, zero mutations |
| **Cadence** | `4h` — every 4 hours |
| **Max tokens / run** | 25,000 |
| **Max runs / day** | 6 |
| **Max wall time** | 4 minutes (240 seconds) |
| **Resumable** | No |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Finds all open issues with no labels: `gh issue list --label ""`
2. Processes up to 20 unlabeled issues per run
3. For each issue, reads the title and body then proposes:
   - **Label(s)** — e.g. `bug`, `enhancement`, `documentation`, `question`
   - **Type** — `bug` / `feature` / `question` / `docs`
   - **Priority** — `critical` / `high` / `medium` / `low`
   - **Reasoning** — a brief explanation for the proposal
4. **Security flag** — if an issue looks like a security report, immediately raises a `human_escalation` exit condition instead of continuing
5. Writes all proposals to `loops/issue-triage/report.md`

---

## What It Will NEVER Do

```
✗ Apply labels to any issue
✗ Post comments on any issue
✗ Close any issue
✗ Merge anything
```

---

## Output

After each run, `loops/issue-triage/report.md` is written:

```markdown
## Issue Triage Report — 2026-08-14T08:00Z

| # | Title | Proposed Labels | Type | Priority | Reasoning |
|---|-------|----------------|------|----------|-----------|
| #55 | Button not working on Firefox | bug, browser-compat | bug | high | User reports specific browser + version. Likely CSS or JS compatibility issue. |
| #56 | Add export to CSV | enhancement | feature | medium | Clear feature request with no urgency signals. |
| #57 | How do I configure the timeout? | question, docs | question | low | User seeking documentation. No bug or feature implied. |
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
agent-toolkit loop run issue-triage
```

---

## When to Upgrade to L2

After the reports are accurate for several consecutive runs, an L2 version can apply labels directly by moving `label` from `deny` to `allowlist` and updating the request prompt to apply rather than propose.

---

## Safety Contract

```yaml
tier: L1
allowlist: []
deny:
  - label
  - comment
  - close
  - merge
```
