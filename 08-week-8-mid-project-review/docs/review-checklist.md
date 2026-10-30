# Review checklist — Week 8 mid-project review

## 1. History audit (before the fix)

Ran on 2026-10-30, before `develop` existed:

```
git log --oneline -15
git branch -a        # only main
git status           # clean
```

Findings:

| # | Problem | Evidence |
|---|---------|----------|
| 1 | Every commit landed directly on `main`; no `develop`, no feature branches | `git branch -a` showed only `main` |
| 2 | Vague, non-conventional messages: `js 06`, `JS05-2`, `radme report`, `update on README.md` | `git log --oneline -15` |
| 3 | No CI, no PR template | no `.github/` directory |
| 4 | No untracked-file problem | working tree was clean |

## 2. Commit message rewrite table (before → after)

Three old messages rewritten into Conventional Commits. The originals stay
in history (they are not force-pushed away); the table is the simulation
exercise, and new commits follow the "after" style from now on.

| Before | After | Why |
|--------|-------|-----|
| `js 06` | `feat(week6): add login, token storage and FCM scaffolding` | "js 06" says nothing: no type, no scope, no what. The rewrite names the feature area and the capability added. |
| `JS05-2` | `feat(week5): add offline-first SQLite storage for announcements` | A bare label only the author understands at commit time. The rewrite says what exists after this commit. |
| `radme report` | `docs(week1): add README report and folder structure` | Typo plus missing type. `docs` signals reviewers that no behavior changed. |
| `update on README.md` | `docs(week7): document clean-architecture layers and run guide` | "update" is true of every commit that touches a file. The rewrite says which part of the README and why. |

## 3. Mid-semester readiness (Lab 3.3)

| Check | Status | Evidence |
|-------|--------|----------|
| Feature-first structure | PASS | `lib/features/{announcement,auth,messaging}` + `lib/core`; see sterility greps below |
| Domain purity grep (`package:flutter` in domain) | PASS | 0 matches |
| Domain purity grep (`dio`/`sqflite`/`firebase` in domain) | PASS | 0 matches |
| Layer direction grep (`/data/` imports in domain or presentation) | PASS | 0 matches — presentation reaches data only through providers/DI |
| `flutter analyze` | PASS | `No issues found!` on 2026-10-30 |
| `dart format --set-exit-if-changed lib test` | PASS | 0 changes needed after the `style(week7)` commit |
| `flutter test` | PASS | 9/9 (3 login use case, 5 announcement validation, 1 router smoke) |
| Small PRs + clear commits | PASS | `feat/announcement-validation` = 1 commit, 2 files, ~80 lines |
| README + run guide | PASS | root README + per-week READMEs; week 8 status in `08-week-8-mid-project-review/README.md` |
| Review comments addressed | IN PROGRESS | PR review flow with the pair happens in GitHub; log decisions in the PR |

Note: `dart format .` is run on `lib test` locally because the committed
Windows `build/` tree contains a broken firebase transform path that crashes
the formatter's directory listing; CI runs on a fresh checkout and uses `.`.

## 4. Definition of done

- [x] App behaves identically to end of Week 7 (validation only rejects rows that were previously rendered broken/blank)
- [x] All three machine checks green locally
- [ ] At least 1 small PR per pair merged through review — `feat/announcement-validation` opened; merge after peer review
- [x] README records mid-semester status + issue/PR map (`08-week-8-mid-project-review/README.md`)
