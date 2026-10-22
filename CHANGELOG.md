# Changelog

All notable changes to this project are documented here. The format follows
[Conventional Commits](https://www.conventionalcommits.org/) and the project uses
[Semantic Versioning](https://semver.org/).

## [0.8.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.7.0...v0.8.0) (2026-10-22)


### Features

* install with Homebrew from a personal tap ([#65](https://github.com/mpellicc/codex-reset-radar/issues/65)) ([94cec9a](https://github.com/mpellicc/codex-reset-radar/commit/94cec9a39b6d2e34fd0d4d59f3272e9b032b6c47))
* localize the app into Italian ([#61](https://github.com/mpellicc/codex-reset-radar/issues/61)) ([74bbaf9](https://github.com/mpellicc/codex-reset-radar/commit/74bbaf91f9e948899adcd145c7deff51417762af))
* update the app in place with Sparkle ([#64](https://github.com/mpellicc/codex-reset-radar/issues/64)) ([8769034](https://github.com/mpellicc/codex-reset-radar/commit/8769034aa0c1f77565fb139969df774862e9343b))


### Bug Fixes

* show settings as switches on the right, like System Settings ([#55](https://github.com/mpellicc/codex-reset-radar/issues/55)) ([13d7f55](https://github.com/mpellicc/codex-reset-radar/commit/13d7f55fac0421196e1b0b8e817ccd420256b41d))
* show the panel countdown in hours and minutes, like the menu bar ([#62](https://github.com/mpellicc/codex-reset-radar/issues/62)) ([46607e3](https://github.com/mpellicc/codex-reset-radar/commit/46607e3d2f0ca4bcace9886b2ad9378736a62741))

## [0.7.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.6.3...v0.7.0) (2026-10-22)


### Features

* add logging with os.Logger ([#51](https://github.com/mpellicc/codex-reset-radar/issues/51)) ([1fad22d](https://github.com/mpellicc/codex-reset-radar/commit/1fad22dd1a2fc87065da57d02d7005635abf1eab))
* turn announced, reminder and landed notifications on or off separately ([#50](https://github.com/mpellicc/codex-reset-radar/issues/50)) ([68b0d4d](https://github.com/mpellicc/codex-reset-radar/commit/68b0d4d23879234c48acd9665bd9aee5a8f84815))

## [0.6.3](https://github.com/mpellicc/codex-reset-radar/compare/v0.6.2...v0.6.3) (2026-10-22)


### Bug Fixes

* size the panel to its content and drop the focus ring ([#47](https://github.com/mpellicc/codex-reset-radar/issues/47)) ([8c355d7](https://github.com/mpellicc/codex-reset-radar/commit/8c355d7dda4724b0993d73ed4b6f65944c45b4a0))


### Documentation

* add latest release and CI badges to the README ([#45](https://github.com/mpellicc/codex-reset-radar/issues/45)) ([fe2b742](https://github.com/mpellicc/codex-reset-radar/commit/fe2b74250d8bdb411771a665dbb1a1b41bfbe086))

## [0.6.2](https://github.com/mpellicc/codex-reset-radar/compare/v0.6.1...v0.6.2) (2026-10-22)

### Miscellaneous

* Build and release process changes only

## [0.6.1](https://github.com/mpellicc/codex-reset-radar/compare/v0.6.0...v0.6.1) (2026-10-22)

### Bug Fixes

* Fix the crash on launch in release builds ([#42](https://github.com/mpellicc/codex-reset-radar/pull/42))

## [0.6.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.5.0...v0.6.0) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Features

* Tell users when a new version is available ([#41](https://github.com/mpellicc/codex-reset-radar/pull/41))

## [0.5.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.4.0...v0.5.0) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Features

* Show minutes in the countdown under 2 hours ([#39](https://github.com/mpellicc/codex-reset-radar/pull/39))
* Add a VoiceOver label to the menu bar item ([#40](https://github.com/mpellicc/codex-reset-radar/pull/40))

## [0.4.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.3.0...v0.4.0) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Features

* Show an offline / error state on the menu bar icon ([#38](https://github.com/mpellicc/codex-reset-radar/pull/38))

## [0.3.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.2.0...v0.3.0) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Features

* Refresh on reconnect, honour 429 / Retry-After, readable errors ([#35](https://github.com/mpellicc/codex-reset-radar/pull/35))

### Documentation

* Document that the first run notifies about an already-pending reset ([#37](https://github.com/mpellicc/codex-reset-radar/pull/37))

## [0.2.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.1.1...v0.2.0) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Features

* Show when notifications are turned off ([#36](https://github.com/mpellicc/codex-reset-radar/pull/36))
* Remind 15 minutes before a pending reset ([#34](https://github.com/mpellicc/codex-reset-radar/pull/34))
* Notify when a reset lands ([#32](https://github.com/mpellicc/codex-reset-radar/pull/32))
* Warn when the app runs from a translocated path ([#33](https://github.com/mpellicc/codex-reset-radar/pull/33))

## [0.1.1](https://github.com/mpellicc/codex-reset-radar/compare/v0.1.0...v0.1.1) (2026-10-22)

**This build crashes on launch on Macs that download it. Use 0.6.1 or later.**

### Bug Fixes

* Fix launch at login toggle state and surface its errors ([#31](https://github.com/mpellicc/codex-reset-radar/pull/31))

## [0.1.0](https://github.com/mpellicc/codex-reset-radar/releases/tag/v0.1.0) (2026-10-22)

### Features

* Menu bar radar that notifies you when a Codex usage reset is announced, with a countdown until it lands
