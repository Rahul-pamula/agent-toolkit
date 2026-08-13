# dep-sweeper

> **Tier L2 — Controlled writes** | Runs once per day | Medium cost

Scans for available **patch-level** dependency updates across all ecosystems in the repository (npm, pip, cargo, etc.), applies them in a worktree, runs the test suite, and opens a **draft PR** per ecosystem if tests pass. It strictly avoids major and minor version bumps — those require human review.

---

## What Problem Does This Solve?

Patch-level updates (e.g. `1.2.3 → 1.2.4`) are low-risk security and bug-fix releases. Ignoring them builds up dependency debt and leaves known vulnerabilities unpatched. This loop handles the safe, mechanical part of dependency maintenance so humans can focus on evaluating major and minor version upgrades.

---

## At a Glance

| Property | Value |
|----------|-------|
| **Tier** | L2 — limited write access |
| **Cadence** | `1d` — once every 24 hours |
| **Max tokens / run** | 50,000 |
| **Max wall time** | 10 minutes (600 seconds) |
| **Resumable** | No |
| **Verifier** | `agent-toolkit-code-reviewer` |

---

## What It Does — Step by Step

1. Detects available updates per ecosystem:
   - **npm**: `npm outdated`
   - **pip**: `pip list --outdated`
   - **cargo**: `cargo outdated`
   - *(other ecosystems detected automatically)*
2. Filters to **patch-level only** — skips any major (`X.0.0`) or minor (`0.X.0`) updates
3. Groups updates by ecosystem
4. For each ecosystem that has patch updates:
   - Creates a worktree to isolate changes
   - Applies the patch updates
   - Runs the test suite (`npm test`, `pytest`, `cargo test`, etc.)
   - **If tests pass** → opens a draft PR titled `chore: patch dep updates (YYYY-MM-DD)`
   - **If tests fail** → posts a comment with the failure details, skips the draft PR
5. Writes `plan.md` summarising: ecosystems checked, updates found, PRs opened, failures

---

## Permitted Actions (Allowlist)

```
✓ create_draft_pr   — open a draft PR with patch updates
✓ comment           — post failure details if tests break
```

## What It Will NEVER Do

```
✗ Merge any PR
✗ Approve any PR
✗ Apply major version updates (e.g. v1 → v2)
✗ Apply minor version updates (e.g. v1.2 → v1.3)
✗ Push directly to main
```

---

## Output

After each run, `loops/dep-sweeper/plan.md` is written with:

```markdown
## Dep Sweeper — 2026-08-14

### Ecosystems Checked
| Ecosystem | Updates Found | Patch Only | PR Opened |
|-----------|--------------|------------|-----------|
| npm | 12 | 8 | ✅ #draft-4 |
| pip | 3 | 3 | ✅ #draft-5 |
| cargo | 0 | 0 | — |

### Skipped (test failures)
- npm: `lodash` patch broke 2 snapshot tests (see comment on draft PR)
```

> **This file is a runtime artifact.** It is generated on every run and should not be committed.

---

## Requirements

- `gh` CLI installed and authenticated (`gh auth login`)
- Ecosystem package managers available in the CI environment (`npm`, `pip`, `cargo`, etc.)
- A runnable test suite for each ecosystem
- Write access to open draft PRs

---

## How to Run

```bash
# Run once manually
agent-toolkit loop run dep-sweeper
```

---

## Safety Contract

```yaml
tier: L2
allowlist:
  - create_draft_pr
  - comment
deny:
  - merge
  - approve
  - major-version-bump
  - minor-version-bump
```
