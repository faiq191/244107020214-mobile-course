# Week 12 — Screenshots

Every image in this folder is a **real capture of the terminal output** produced
by the commands run in this folder — not a mock-up. Each PNG is the exact text
those commands printed, rendered onto a dark terminal background by
[`render.ps1`](render.ps1) so the raw output is preserved as an image.

> Why render instead of a window screenshot? The runs were done in a headless
> shell where a literal window capture is not possible. The text content is
> byte-for-byte what the tools printed; the script only paints it. Re-run the
> script against fresh output to regenerate any file.

| File | Command | What it shows |
|---|---|---|
| `01-flutter-test.png` | `flutter test` | The full unit + widget suite: **39 tests, all passed** |
| `02-flutter-analyze.png` | `flutter analyze` | Static analysis: **No issues found** |
| `03-coverage-run.png` | `flutter test --coverage` | The same suite run with coverage enabled |
| `04-coverage-summary.png` | (parsed `coverage/lcov.info`) | Per-file **line coverage** and the total |
| `05-integration-test.png` | `flutter test integration_test/app_test.dart -d emulator-5554` | The end-to-end flow **passing on the Android emulator** |

## Green-Machine Evidence blocks

The `ev-*.png` files are the same command output rendered for the
**Green-Machine Evidence** section of the README (one image per command block):

| File | Block |
|---|---|
| `ev-01-analyze.png` | `flutter analyze` |
| `ev-02-test.png` | `flutter test` |
| `ev-03-coverage.png` | `flutter test --coverage` |
| `ev-04-integration.png` | `flutter test integration_test/app_test.dart -d emulator-5554` |
| `ev-05-format.png` | `dart format --set-exit-if-changed` |

## The integration test run

The end-to-end test builds, installs and runs the full flow on the `Pixel_8`
AVD (`emulator-5554`, Android 17 / API 37):

```text
00:00 +0: a user can add an announcement and see it in the list
00:11 +1: (tearDownAll)
00:12 +1: All tests passed!
```

If the AVD starts `offline` and never clears, a cold boot with software
rendering fixes it (web is not supported for integration tests, and Windows
needs the C++ toolchain):

```bash
"$ANDROID_SDK/emulator/emulator.exe" -avd Pixel_8 \
  -no-snapshot -no-boot-anim -gpu swiftshader_indirect -no-audio
adb wait-for-device
flutter test integration_test/app_test.dart -d emulator-5554
```
