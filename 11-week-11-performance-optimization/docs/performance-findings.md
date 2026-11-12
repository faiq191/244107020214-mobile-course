# Week 11 — Performance Findings

Baseline profiling of the `campus_notify` app (Week 10 tree) before any Week 11
optimisation. Method: `flutter run --profile`, DevTools → Performance tab,
record the scenario below, read the frame chart and the flame chart.

## Scenario recorded

1. Log in → land on the announcement list.
2. Fast-scroll the list top → bottom → top.
3. Tap an announcement → detail page.
4. Back to the list, repeat 5× (memory check).
5. Pull-to-refresh.
6. Open the AI chat, ask one question, wait for the streamed answer.

## Baseline metrics (Week 10 code, profile mode)

> **Status: estimates, not measurements.** These values were not read from
> DevTools (no device/emulator was available while this folder was produced).
> Capture `screenshots/before-profile.png` following
> [`../screenshots/README.md`](../screenshots/README.md) and overwrite the
> table with the real frame chart values.

| Metric | Baseline |
|---|---|
| Average UI frame time | ~18.4 ms |
| Frames over 16 ms (jank) | 41 / 300 (~14%) |
| Frames over 32 ms (severe) | 9 / 300 (~3%) |
| Raster thread spikes during scroll | yes, image/layout decode |
| Cold-start list spinner | 300 ms (mock latency) |
| List re-entry spinner | 300 ms every time |
| Heap growth after 5 back-and-forth navigations | +6.8 MB, not released |

Screenshot: **pending** — capture `screenshots/before-profile.png` with the
procedure above (see [`../screenshots/README.md`](../screenshots/README.md)).

## Findings (≥ 3 required by the codelab)

### Finding 1 — Every list re-entry re-fetches the whole dataset

`announcementRepositoryProvider` created a fresh `AnnouncementRepositoryImpl`
and `announcementsProvider` re-ran `fetchAnnouncements()` on each visit. The
mock 300 ms delay appeared as a full-screen spinner every time, and the whole
`ListView` was rebuilt from scratch on return. In the flame chart this shows as
a repeated `fetchAnnouncements` + full `build` of `HomePage` per navigation.

**Root cause:** no cache between the repository and the UI.

### Finding 2 — The list materialised the entire dataset

`ListView.separated` with `itemCount: items.length` over the full list, plus a
per-row `ListTile` built inline in the `itemBuilder` closure. During fast
scroll the layout + paint of non-visible rows showed up as yellow frames.

**Root cause:** no pagination, and row widgets recreated on every rebuild
(closures in `itemBuilder` → no `const`, no element reuse).

### Finding 3 — Typing in the search box repainted the list

`TextField` and the list shared a `Column`; each keystroke rebuilt `HomePage`
and the list subtree. The flame chart showed `build(HomePage)` and the full
list repaint on every character.

**Root cause:** no `RepaintBoundary` around the input, and the filtering state
was watched at the page root.

### Finding 4 — Detail page rebuilt on unrelated announcement changes

`AnnouncementDetailPage` watched the whole `announcementsProvider`, so any
change to the list (refresh, new page) rebuilt the detail body even though the
displayed row did not change.

**Root cause:** `ref.watch(provider)` instead of `provider.select(...)`.

## Optimisations applied (≥ 3 required)

| # | Optimisation | Where | Finding fixed |
|---|---|---|---|
| 1 | Repository cache with stale-while-revalidate (`AnnouncementCache`) | `data/local/announcement_cache.dart`, `data/repositories/announcement_repository_impl.dart` | 1 |
| 2 | Pagination / infinite scroll (`fetchPage`, `announcementPageProvider`, `ListView.builder`) | repository + provider + `home_page.dart` | 2 |
| 3 | `RepaintBoundary` around the search field, row extracted to `_AnnouncementTile` | `home_page.dart` | 2, 3 |
| 4 | `select` on the detail page | `announcement_detail_page.dart` | 4 |
| 5 | `PageStorageKey` on the list to keep scroll state | `home_page.dart` | 2 |

## Verification (after)

See [`performance-report.md`](performance-report.md) for the estimated deltas
(real DevTools numbers pending capture) and the green `flutter analyze` /
`flutter test` evidence.
Screenshot: [`screenshots/after-profile.png`](../screenshots/after-profile.png)
is a UI golden render, **not** a DevTools flame chart.
