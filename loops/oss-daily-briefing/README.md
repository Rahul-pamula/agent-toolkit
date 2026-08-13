# oss-daily-briefing

> **Tier L1 — Read-only** | Runs once per day | Low cost | Resumable

Produces a daily read-only briefing across all configured OSS repositories. For each repo it collects new pull requests, issues needing attention, and CI health on the main branch, then writes a structured report. Nothing is modified — the loop is pure observation.

---

## What Problem Does This Solve?

Maintaining multiple open-source repositories means checking many dashboards every morning. This loop consolidates that into a single daily report: new activity, things needing attention, and CI health — all in one place.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L1 — read-only, zero mutations |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 80,000 |
| **Max wall time** | 15 minutes (900 seconds) |
| **Resumable** | Yes — uses `STATE.md` checkpoints |
| **Verifier** | None |

---

## What It Does — Step by Step

1. Reads `loops/oss-daily-briefing/STATE.md` — if `last_processed_repo` is set, resumes from where the previous run stopped
2. For each configured repo, collects:
   - **New PRs** in the last 24 hours
   - **New issues** or issues with recent activity
   - **CI status** on the main branch
3. After processing each repo, writes a checkpoint to `STATE.md`
4. Writes the full briefing to `loops/oss-daily-briefing/report.md`
5. On successful completion, clears `last_processed_repo` in `STATE.md`

---

## What It Will NEVER Do

```
✗ Comment on any issue or PR
✗ Apply labels
✗ Assign anyone
✗ Merge anything
✗ Approve anything
✗ Push or force-push
```

---

## Resumability

This loop is **resumable**. If it hits the token budget mid-run, it writes its current position to `STATE.md`:

```markdown
last_processed_repo: owner/repo-name
last_run: 2026-08-14T02:30:00Z
last_run_status: partial (budget_exhausted)
```

The next scheduled run reads this file and skips the repos that were already processed. This allows the loop to reliably cover large multi-repo ecosystems even with conservative token budgets.

> `STATE.md` is a runtime artifact. Do not commit it.

---

## Output

After a complete run, `loops/oss-daily-briefing/report.md` looks like:

```markdown
## OSS Daily Briefing — 2026-08-14

### New PRs (last 24h)
| Repo | # | Title | Author |
|------|---|-------|--------|
| owner/repo-a | #88 | feat: add retry logic | alice |
| owner/repo-b | #34 | fix: null pointer in parser | bob |

### Issues Needing Attention
| Repo | # | Title | Last Comment |
|------|---|-------|-------------|
| owner/repo-a | #71 | Memory leak on long sessions | 3 days ago |

### CI Health
| Repo | Status |
|------|--------|
| owner/repo-a | ✅ passing |
| owner/repo-b | ❌ failing (2 jobs) |

### Highlights
- owner/repo-a shipped v2.1.0 yesterday
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`)
- Read access to all configured repositories
- For large ecosystems (10+ repos): ensure `resumable: true` is set and `max_tokens` is sized appropriately (see token budget table in `docs/HOW_TO_CREATE_LOOP.md`)

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run oss-daily-briefing
```

---

## Safety Contract

```yaml
tier: L1
allowlist: []
deny:
  - comment
  - label
  - assign
  - merge
  - close
  - push
  - approve
  - force-push
```
