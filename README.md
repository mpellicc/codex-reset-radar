<img src="docs/assets/icon.png" alt="" width="128" height="128">

# Codex Reset Radar

[![Latest release](https://img.shields.io/github/v/release/mpellicc/codex-reset-radar?label=release)](https://github.com/mpellicc/codex-reset-radar/releases/latest)
[![CI](https://github.com/mpellicc/codex-reset-radar/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mpellicc/codex-reset-radar/actions/workflows/ci.yml)

A tiny macOS menu bar app that pings you when a Codex usage reset is announced,
with a countdown to when it lands.

Data from [codex-resets.com](https://codex-resets.com).

## Install

1. Download the [latest build](https://github.com/mpellicc/codex-reset-radar/releases/latest/download/CodexResetRadar.zip), unzip it and drag **Codex Reset Radar.app** to Applications.
2. Open it. macOS will refuse because the app isn't from an identified developer.
3. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to
   "Codex Reset Radar", then confirm. You only do this once.
4. Allow notifications when asked.
5. Click the radar icon in the menu bar and turn on **Launch at login**.

Requires macOS 13 or later.

## What it does

- Checks codex-resets.com every 15 minutes and after your Mac wakes.
- When a reset with a date is announced, sends a notification (and another if the time changes).
- Shows a countdown next to the menu bar icon (`9h`, `1h 59m`, `45m`, `due`) until it lands.
- Speaks your macOS language (English or Italian so far); announcement posts stay in their original wording.

## Build

```bash
scripts/build-app.sh
```

Produces `dist/Codex Reset Radar.app` and `dist/CodexResetRadar-<version>.zip`.
Needs Xcode (for the universal arm64 + x86_64 build). See [SPEC.md](SPEC.md) for behaviour.

To format the code before committing, run `swift format --in-place --recursive Sources Tests`.

### Releasing

The project follows [Semantic Versioning](https://semver.org/) and
[Conventional Commits](https://www.conventionalcommits.org/), and releases with
[release-please](https://github.com/googleapis/release-please). Don't tag by hand or edit the
version in `Resources/Info.plist`.

Pull requests are squash-merged, and their title becomes the commit on `main`, so it must be a
Conventional Commit (a check enforces it):

| Title | Example | Next version (before 1.0) |
|---|---|---|
| `feat:` | `feat: show the watch forecast` | minor |
| `fix:` | `fix: keep the panel sized to its content` | patch |
| `feat!:` or a `BREAKING CHANGE:` footer | `feat!: drop macOS 13` | minor (major after 1.0) |
| `docs:`, `chore:`, `ci:`, `refactor:`, `test:`, `build:` | `ci: build on Xcode 27` | none on their own |

release-please keeps a Release PR open that collects everything merged since the last release:
the next version, the `CHANGELOG.md` entry and the version in `Info.plist`. Merging it is the
release: the workflow tags it, builds and signs the app, attaches `CodexResetRadar.zip` and
publishes the GitHub release.

## License

The code is released under the [MIT License](LICENSE).

Reset data comes from [codex-resets.com](https://codex-resets.com) and is not covered by this
license. Anything that shows it must keep crediting codex-resets.com with a link, as
[SPEC.md](SPEC.md) requires.
