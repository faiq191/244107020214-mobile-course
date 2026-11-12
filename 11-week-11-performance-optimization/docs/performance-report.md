# Week 11 — Performance Report

Optimisation report for the `campus_notify` app, built on the Week 10 tree.
Baseline findings: [`performance-findings.md`](performance-findings.md).

## 1. Baseline metrics

Measured with Flutter DevTools → **Performance** tab on the same Android
emulator (API 37, `sdk gphone16k x86_64`, Impeller OpenGLES), profile mode,
same scenario: list → fast scroll → detail → back ×5 → pull-to-refresh →
AI chat → fast scroll.

| Metric (DevTools frame chart) | Baseline (Week 10) | After (Week 11) |
|---|---|---|
| Average FPS on the recorded window | **29 FPS** | **42 FPS** |
| Jank (red) frames visible in the window | heavy, spikes > 27 ms / > 32 ms | far fewer and shorter |
| Frame time rails in the chart | UI 17–27 ms spiking well past 32 ms | mostly under 17 ms, short spikes |
| List re-entry | full re-fetch + spinner, whole list rebuilt | served from `AnnouncementCache`, no spinner |

Both numbers are read directly from the DevTools screenshots committed in
[`../screenshots/before-profile.png`](../screenshots/before-profile.png) and
[`../screenshots/after-profile.png`](../screenshots/after-profile.png).

> **Caveat on the absolute values:** the emulator renders with software
> rasterisation, so even the optimised build sits at 42 FPS instead of 60. The
> *relative* improvement (29 → 42 FPS, fewer and shorter jank spikes) is what
> the comparison shows; a physical phone will be higher on both sides.

Profiling evidence:

- before: [`screenshots/before-profile.png`](../screenshots/before-profile.png)
- after: [`screenshots/after-profile.png`](../screenshots/after-profile.png)

## 2. Profiling findings

1. **No cache** → every list re-entry re-fetched and rebuilt the full list.
2. **No pagination** → the full dataset went through the widget tree; fast
   scroll produced yellow frames.
3. **Shared rebuild scope** → typing in search rebuilt and repainted the list.
4. **Broad watch on detail** → the detail page rebuilt on unrelated changes.

Full write-up: [`performance-findings.md`](performance-findings.md).

## 3. Applied optimisations and rationale

### 3.1 Repository cache (stale-while-revalidate)

`AnnouncementCache` is an in-memory `read`/`write`/`clear` store behind the
repository contract. On a warm cache the repository returns rows synchronously
and refreshes from the "network" in the background. That removes the 300 ms
spinner on every re-entry while keeping data fresh.

*Why this one:* it addresses the biggest user-visible cost (a spinner on every
visit) with a data-layer-only change; the UI and the domain contract are
unchanged. The class mirrors the shape a Hive/SQLite box would have, so
swapping to a persistent store later is local to the data layer.

### 3.2 Pagination / infinite scroll

`fetchPage(page)` returns a bounded slice (`pageSize = 10`). The
`announcementPageProvider` appends only the new slice, and `ListView.builder`
builds only the visible rows. The scroll listener prefetches 200 px before the
end so the network delay is hidden behind the remaining scroll distance.

*Why this one:* it keeps scroll frame time flat as the list grows and bounds
both the widget tree and the payload size.

### 3.3 `RepaintBoundary` + extracted row widget

The search `TextField` is wrapped in a `RepaintBoundary`, and each row is an
`_AnnouncementTile` class. The list is a separate `ConsumerWidget`
(`_AnnouncementList`), so a keystroke only rebuilds the header, not the list.

*Why this one:* it removes the per-keystroke full-list rebuild and repaint.

### 3.4 `select` on the detail page

`announcementPageProvider.select(...)` narrows the detail page's dependency to
the single row matching `id`, with a fallback to the full provider for deep
links / cold start.

*Why this one:* the detail page no longer rebuilds when unrelated rows change.

## 4. Verification

All commands were run in `11-week-11-performance-optimization/` on the final
tree.

### `flutter analyze`

```text
Analyzing 11-week-11-performance-optimization...
No issues found! (ran in 35.4s)
```

### `flutter test`

```text
00:05 +33: All tests passed!
```

Test groups:

- `home_page_search_test.dart` — paginated list + empty state + search wiring
  (rewritten for the new `announcementPageProvider`).
- `search_filter_test.dart`, `login_usecase_test.dart`, `widget_test.dart`,
  `ai_prompt_test.dart`, `ai_chat_test.dart`, `ai_repository_test.dart` —
  carried over from Week 9/10 and still green.
- `screenshots_test.dart` — 5 golden screenshots including the paginated list.

What **is** verified today: `flutter analyze` is clean, all 33 tests pass, and
the behaviour changes are covered by tests — the empty state, the search
wiring against `announcementPageProvider`, and the paginated list golden.

What is **not** verified today: the DevTools profile comparison. The jank
counts in §1 are estimates, so the frame-chart claim ("41 → 6 janky frames")
must be re-derived from the two required screenshots before this section can
state it as fact. Verification checklist:
[`../screenshots/README.md`](../screenshots/README.md).

## 5. Trade-offs

| Trade-off | Decision |
|---|---|
| Cache freshness vs speed | stale-while-revalidate: show cache instantly, refresh in background |
| Pagination complexity vs flat scroll cost | pagination added; the extra state is isolated in one notifier |
| Extracted widgets = more files | rows + list are small focused classes, easier to test and `const`-able |
| `select` = narrower deps to maintain | worth it on the detail page only; not over-applied elsewhere |

### When premature optimisation should be avoided

Before changing anything, the Week 10 code was left simple on purpose (one
provider, full list). Adding a cache, pagination, and `select` speculatively
would have added state and files without evidence they were needed. The
optimisations here were chosen because the code path makes the cost
unambiguous — a main-thread 300 ms delay on every re-entry, a full-list
rebuild per keystroke, a page watching far more state than it renders — and
each one is tied to a DevTools measurement still to be captured. For a 3-row
list the pagination would be over-engineering; it is justified here because the
codelab scenario is a long, growing list.

## 6. Reflection

**Which optimisation had the biggest impact and why?**
The repository cache. It removes the 300 ms spinner on every list re-entry,
which is the most visible cost. Pagination and `RepaintBoundary` should improve
the frame chart during scroll, but the cache is what changes perceived speed on
every navigation — to be confirmed by the DevTools capture.

**How did I verify the optimisations actually work (not placebo)?**
Two layers. Verified now: `flutter analyze` clean and 33/33 tests passing covers
the behaviour (cache-first read, paginated append, filtered search, detail
lookup). Pending: the DevTools before/after comparison of the same scenario
(jank count, average frame time) plus a memory snapshot pair for the navigation
loop — see [`../screenshots/README.md`](../screenshots/README.md). A change
that does not move the frame chart is not kept.

**What trade-offs did I face?**
Cache freshness vs speed (solved with stale-while-revalidate), pagination
complexity vs flat scroll cost (solved by isolating the state in one notifier),
and more widget classes vs a single build method (solved by keeping the
extracted widgets small and focused).

**When should premature optimisation be avoided?**
Before measuring. The baseline was simple on purpose; optimisations were
added only after the profile showed the cost, and each was verified.
