<img src="docs/assets/icon.png" alt="" width="128" height="128">

# Codex Reset Radar

[![Latest release](https://img.shields.io/github/v/release/mpellicc/codex-reset-radar?label=release)](https://github.com/mpellicc/codex-reset-radar/releases/latest)
[![CI](https://github.com/mpellicc/codex-reset-radar/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mpellicc/codex-reset-radar/actions/workflows/ci.yml)

A tiny macOS menu bar app that pings you when a Codex usage reset is announced,
with a countdown to when it lands.

Data from [codex-resets.com](https://codex-resets.com).

## Install

With [Homebrew](https://brew.sh):

```bash
brew install --cask mpellicc/tap/codex-reset-radar
```

Then open the app and continue from step 3 below: Homebrew downloads count as from the internet too,
so the first launch still needs "Open Anyway". `brew uninstall --zap codex-reset-radar` removes the app
and its preferences.

Or by hand:

1. Download the [latest build](https://github.com/mpellicc/codex-reset-radar/releases/latest/download/CodexResetRadar.zip), unzip it and drag **Codex Reset Radar.app** to Applications.
2. Open it. macOS will refuse because the app isn't from an identified developer.
3. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to
   "Codex Reset Radar", then confirm. You only do this once.
4. Allow notifications when asked.
5. Click the radar icon in the menu bar and turn on **Launch at login**.

Requires macOS 15 or later.

The app keeps itself up to date: it checks once a day, or when you click **Check for Updates…** in the
panel, and installs new versions in place without another "Open Anyway". Versions 0.7.0 and older
can't do this, so update from those once by hand.

## What it does

- Checks codex-resets.com every 15 minutes and after your Mac wakes.
- When a reset with a date is announced, sends a notification (and another if the time changes).
- Shows a countdown next to the menu bar icon (`9h`, `1h 59m`, `45m`, `due`) until it lands.
- Lets you turn announced, reminder and landed notifications on or off separately, from the panel, and choose how long before a reset the reminder comes (5, 15, 30 or 60 minutes).
- Notification sound follows macOS: use the per-app "Play sound for notifications" switch in System Settings → Notifications → Codex Reset Radar (the panel's "Open Notification Settings" button takes you there).
- Speaks your macOS language (English or Italian so far); announcement posts stay in their original wording.

## Troubleshooting

If a notification didn't arrive or the app misbehaves, it logs every poll and notification decision.
Run this in Terminal and paste the output into your bug report:

```bash
log show --last 1d --predicate 'subsystem == "dev.mpellicc.CodexResetRadar"' --info
```

The log holds only public data: reset ids, announcement text, times and HTTP status codes.

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
release: the workflow tags it, builds and signs the app, signs `CodexResetRadar.zip` for Sparkle,
attaches it with `appcast.xml`, publishes the GitHub release and bumps the version and `sha256` of
the cask in [mpellicc/homebrew-tap](https://github.com/mpellicc/homebrew-tap). Installed apps find the update through
`releases/latest/download/appcast.xml`.

Update signing needs the EdDSA private key in the `SPARKLE_PRIVATE_KEY` repository secret; the job
fails without it, or when it doesn't match `SUPublicEDKey` in `Info.plist`. The key was made with
Sparkle's `generate_keys --account codex-reset-radar` and is kept in its owner's login Keychain. To export
it (for the secret or a backup), after any `swift build`:

```bash
.build/artifacts/sparkle/Sparkle/bin/generate_keys --account codex-reset-radar -x sparkle-private-key.txt
```

Never commit that file. Losing the key means every user has to install the next release by hand.

The cask bump needs `HOMEBREW_TAP_TOKEN`: a fine-grained token with Contents read and write access to
`mpellicc/homebrew-tap` only. Without it the release still publishes, but the job fails at the last step
and Homebrew keeps offering the previous version. `scripts/setup-release-secrets.sh` walks through
setting both secrets.

## License

The code is released under the [MIT License](LICENSE).

Reset data comes from [codex-resets.com](https://codex-resets.com) and is not covered by this
license. Anything that shows it must keep crediting codex-resets.com with a link, as
[SPEC.md](SPEC.md) requires.
