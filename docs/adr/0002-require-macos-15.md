# Require macOS 15

The minimum macOS goes from 13 to 15 (Sequoia). It unlocks the SF Symbol effects (`.rotate`,
`.breathe`, `variableColor`) the menu bar animations need, and newer SwiftUI and App Intents APIs,
and it lets us drop the `#available` checks that kept the code working on 13.

`Package.swift` declares `.macOS(.v15)` and `Info.plist` sets `LSMinimumSystemVersion` to `15.0`.
`scripts/make-appcast.sh` copies that value into `sparkle:minimumSystemVersion` on every appcast item,
so Sparkle never offers a build that won't launch to a Mac that can't run it.

## Consequences

- Users on macOS 13 and 14 stay on the last release that supports them and stop getting updates,
  including fixes. They see no error: Sparkle just reports that they are up to date.
- The requirement lives in one place, `Info.plist`; the appcast follows it. Raising it again later
  needs no change to the release script.
- The build is a breaking change, so the PR is titled `feat!:` and release-please bumps the version
  accordingly.
