# Changelog

All notable changes to this project are documented here. The format follows
[Conventional Commits](https://www.conventionalcommits.org/) and the project uses
[Semantic Versioning](https://semver.org/).

## [0.10.1](https://github.com/mpellicc/codex-reset-radar/compare/v0.10.0...v0.10.1) (2026-10-23)


### Documentation

* update README for current app features ([e6e4156](https://github.com/mpellicc/codex-reset-radar/commit/e6e415622eace203b2e0076d20cf6d8120cf2b5d))

## [0.10.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.9.1...v0.10.0) (2026-10-23)


### Features

* add two easter eggs ([#83](https://github.com/mpellicc/codex-reset-radar/issues/83)) ([e5c404e](https://github.com/mpellicc/codex-reset-radar/commit/e5c404ed317c0bcc57e952c485cb269b1606787b))
* animate the menu bar icon on events ([#87](https://github.com/mpellicc/codex-reset-radar/issues/87)) ([cc5e798](https://github.com/mpellicc/codex-reset-radar/commit/cc5e7981ddfa147e4382fb93179a77749c51cc2c))
* draw the menu bar radar as a layered symbol ([#84](https://github.com/mpellicc/codex-reset-radar/issues/84)) ([dc86bcf](https://github.com/mpellicc/codex-reset-radar/commit/dc86bcf0db4961a79035555b23b02a45c0bcf221))

## [0.9.1](https://github.com/mpellicc/codex-reset-radar/compare/v0.9.0...v0.9.1) (2026-10-23)


### Bug Fixes

* record the real SDK version so the app gets the current macOS look ([#85](https://github.com/mpellicc/codex-reset-radar/issues/85)) ([5ea6b94](https://github.com/mpellicc/codex-reset-radar/commit/5ea6b94b6a08dbb182e05de5929f602b2e37bca2))

## [0.9.0](https://github.com/mpellicc/codex-reset-radar/compare/v0.8.0...v0.9.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* the minimum macOS is now 15.

### Features

* add a Shortcuts action for the next reset ([#82](https://github.com/mpellicc/codex-reset-radar/issues/82)) ([f4507a6](https://github.com/mpellicc/codex-reset-radar/commit/f4507a65d2578cf0390d70c209be57c2e341f93b))
* choose the reminder lead time ([#80](https://github.com/mpellicc/codex-reset-radar/issues/80)) ([69e3042](https://github.com/mpellicc/codex-reset-radar/commit/69e304230ba40d78de842c5328f74b4a8e0c9108))
* require macOS 15 ([#79](https://github.com/mpellicc/codex-reset-radar/issues/79)) ([d1005d7](https://github.com/mpellicc/codex-reset-radar/commit/d1005d7d1d61092e2cc4ff164999bbbc527f3d5c))
* show the watch forecast in the panel ([#81](https://github.com/mpellicc/codex-reset-radar/issues/81)) ([3b4744c](https://github.com/mpellicc/codex-reset-radar/commit/3b4744c2d39358dc58bce0050c4d26d26aa3c4df))


### Bug Fixes

* translate the panel's switch labels ([#77](https://github.com/mpellicc/codex-reset-radar/issues/77)) ([4129a51](https://github.com/mpellicc/codex-reset-radar/commit/4129a51bc049b02cde9fb6ff30ba4aa70a93d3e4)), closes [#66](https://github.com/mpellicc/codex-reset-radar/issues/66)


### Documentation

* add a localization guide for agents ([364af7e](https://github.com/mpellicc/codex-reset-radar/commit/364af7e576505116583f20d47fec1d284257cfc5))

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
