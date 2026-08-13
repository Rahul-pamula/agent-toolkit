# oss-pr-monitor

> **Tier L3 — High Autonomy (Merge/Close Allowlisted)** | Runs once per day | High cost | Resumable

Monitors open pull requests across a multi-repository open-source software (OSS) ecosystem. It evaluates open PRs, auto-merges Dependabot PRs with passing CI, closes broken Dependabot PRs, and drafts diagnoses for failing human PRs. Because it merges and closes PRs, it requires L3 permissions.

---

## What Problem Does This Solve?

Maintaining 20–50 repositories means dealing with constant dependency bumps (e.g., from Dependabot) and pull requests. Checking every single one manually takes significant time. This loop automates the clean, mechanical updates (merging passing Dependabot PRs) and organizes human-submitted PRs into a checklist report so you only need to focus on what requires human review.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L3 — High-autonomy (Merge/Close allowed) |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 300,000 |
| **Max runs / day** | 1 |
| **Max wall time** | 30 minutes (1800 seconds) |
| **Resumable** | Yes — uses `STATE.md` checkpoints |
| **Verifier** | `agent-toolkit-code-reviewer` |

> ⚠️ **L3 loops are high-autonomy.** They possess merge and close capabilities. Ensure you run this loop in L1 report-only mode first to observe its decisions before enabling mutations in a production environment.

---

## What It Does — Step by Step

1. Reads `loops/oss-pr-monitor/STATE.md` to resume from the last processed repository if interrupted.
2. For each configured repository in the pack:
   - Lists open PRs using the GitHub API.
   - Classifies each PR: Dependabot PR, other Bot PR, or Human PR.
3. Takes action on Dependabot PRs:
   - Checks CI test status.
   - **All checks passing** → Merges the PR silently (`gh pr merge --squash`).
   - **CI checks failing** → Skips and notes in the report.
   - **Dirty/conflict state** → Closes the PR (`gh pr close`) so Dependabot can regenerate it.
4. Triages Human PRs:
   - Reads the diff summary, checks CI status, and flags merge conflicts.
   - Proposes feedback in `report.md` but **never merges or closes human PRs**.
5. Saves a checkpoint to `STATE.md` after each repository.
6. Writes a detailed summary to `loops/oss-pr-monitor/report.md` on completion.

---

## Permitted Actions (Allowlist)

```
✓ merge     — Merge passing Dependabot PRs
✓ close     — Close broken/dirty Dependabot PRs
✓ comment   — Write diagnostic help on human PRs
✓ label     — Label PRs based on triage classification
```

## What It Will NEVER Do

```
✗ Approve human PRs
✗ Merge human PRs
✗ Force-push to any branch
✗ Directly push commits to main/master branches
✗ Delete repository branches
```

---

## Output

Writes a checklist report to `loops/oss-pr-monitor/report.md`:

```markdown
## OSS PR Monitor Report — 2026-08-14

| # | Repo | Title | Author | Type | CI | Action | Pending Reason |
|---|------|-------|--------|------|----|--------|----------------|
| #10 | org/repo-a | bump lodash from 1.0.0 to 1.0.1 | dependabot | Dep | ✅ Passing | Merged | — |
| #12 | org/repo-a | fix: handle socket timeout | human-dev | Human | ❌ Failing | None | CI Failing; needs contributor update |
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated with write/merge permissions (`gh auth login`).
- A configured client context pack (e.g., `packs/my-ecosystem.yaml`) defining the repositories to scan.

---

## How to Run

```bash
# Run with a repository pack definition
agent-toolkit loop run oss-pr-monitor --pack packs/my-ecosystem.yaml
```

---

## Safety Contract

```yaml
tier: L3
allowlist:
  - merge
  - close
  - comment
  - label
deny:
  - approve
  - force-push
  - push-to-main
  - delete-branch
```
