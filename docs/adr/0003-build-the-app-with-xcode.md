# Build the app with Xcode

The `.app` is built by Xcode from a project that XcodeGen generates from `project.yml`. `scripts/build-app.sh`
used to build it with SwiftPM and copy into place, by hand, the parts of a bundle that only Xcode makes: the
`Sparkle.framework` embed, the App Intents metadata and the Siri phrase assets. Apple supports building Mac
apps with Xcode only; SwiftPM is for packages, and none of those hand-run steps has a documented contract.

The cost of that showed in 0.9.0. Moving the build to Swift Build (`--build-system swiftbuild`), to get the
constant values the App Intents step reads, made the binary record its deployment target (15.0) where the SDK
version belongs. macOS picks an app's look from that number, so 0.9.0 opened with the pre-Liquid Glass windows
and controls. Xcode records the SDK it built with.

`project.yml` is the spec and the generated `CodexResetRadar.xcodeproj` is not committed: a hand-edited
`project.pbxproj` is hard to review and merge. `Package.swift` stays for `swift build`, `swift test` and
`swift run`, so the code still builds and tests without Xcode's project.

## Consequences

- Building the app needs XcodeGen (`brew install xcodegen`), locally and on CI.
- `Package.resolved` stays the one pin for Sparkle. `build-app.sh` copies it into the generated project and
  builds with `-onlyUsePackageVersionsFromResolvedFile`, so the app and `swift build` use the same version.
- RadarCore is a static library target in the project, built from the same sources as the package target.
  New source files need no change in either place; new targets or dependencies need one in both.
- Xcode trains Siri phrase assets (`nlu.appintents`) only for iOS-family platforms, so the bundle no longer
  carries them. The App Shortcut phrases and their Italian strings are still in the bundle, as in any
  Xcode-built Mac app.
- `build-app.sh` still checks the recorded SDK version, both architectures, the App Intents metadata and the
  signature, so a change in how Xcode builds fails the build instead of reaching users.
