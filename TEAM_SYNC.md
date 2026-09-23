# Team Sync Guide — Read Before Pushing

**Date: 2026-09-24** — The git history was rewritten (bot co-author trailers removed
from every commit) and all branches were force-pushed to GitHub. Your local branches
therefore point at **old commits that no longer exist on GitHub**.

A normal `git pull` or `git push` will fail or, worse, resurrect the old history.
Follow the steps below for your branch — it takes under a minute.

---

## TL;DR

```bash
git fetch origin
git checkout <your-branch>
git reset --hard origin/<your-branch>
git pull --rebase
```

> ⚠️ `git reset --hard` discards uncommitted work. If you have changes you want to
> keep, stash them first: `git stash push -u -m "wip before resync"` — and pop it
> after the reset: `git stash pop`.

---

## Per-branch commands

### Kajana — branch `Kajana`
```bash
git fetch origin
git checkout Kajana
git reset --hard origin/Kajana
```

### Sureka — branch `suka`
```bash
git fetch origin
git checkout suka
git reset --hard origin/suka
```

### Ahsan — branch `dev/swami` (already done on this machine)
```bash
git fetch origin
git checkout dev/swami
git reset --hard origin/dev/swami
```

### Anyone on `main` or `feature/ahsan-dev`
```bash
git fetch origin
git checkout main
git reset --hard origin/main
```

### Old branch `feat/buyer-flow-and-architecture-...`
Same pattern: `git reset --hard origin/feat/buyer-flow-and-architecture-10695578080625655474`

---

## After resyncing

1. Refresh dependencies (the recent merge changed `pubspec.yaml`):
   ```bash
   flutter pub get
   ```
2. Verify everything is green locally:
   ```bash
   flutter analyze
   flutter test        # 148 tests should pass
   ```
3. Work normally — commit, then `git push` (regular pushes only; force-pushes to
   `main` and `dev/swami` are now blocked by branch protection).

---

## What changed and why

- GitHub's contributors list showed **Codebuff** and **Copilot** as contributors.
  They got there via `Co-Authored-By:` trailers that coding agents add to commit
  messages — never as commit authors.
- All bot trailers were stripped from every commit message across all branches
  (code content, authors, and dates are byte-identical; only messages changed).
- `main` and `dev/swami` are now protected: **no force-push, no delete**. Regular
  feature branches still accept force-pushes in case cleanup is ever needed again.

## Current branch tips (for reference)

| Branch | Tip commit | Subject |
|---|---|---|
| `main` | `4fb2b47` | Merge pull request #5 from AHSANMOHAMMED/dev/swami |
| `dev/swami` | `55bafbc` | fix: address Copilot review — security, rules, timestamps, tracking |
| `suka` | `9dc6103` | transportor ui |
| `Kajana` | `715f288` | Update profile screen |
| `feature/ahsan-dev` | `edfa795` | feat(admin): add Security Audit Trail, Treasury Escrow Settlements… |

If your local tip does not match the table above **after** resyncing, ping Ahsan
before pushing anything.
