# Update in place with Sparkle

The app updates itself with [Sparkle](https://sparkle-project.org), added as the package's only
dependency. It checks an appcast once a day and on "Check for Updates…", then downloads, verifies,
installs and relaunches through Sparkle's standard windows. This replaces our own GitHub release check
and its "Version X available — Download" row.

It reverses two earlier decisions: SPEC.md's "Swift Package with no dependencies" and the
"checking yes, installing no" scope of #16. Updating by hand meant downloading the zip, replacing the app
and going through Gatekeeper's "Open Anyway" again, every release, and nobody could ask for a check.
Writing a safe in-place installer ourselves (signature checks, replacing a running app, relaunching) is
exactly what Sparkle already does well.

Updates are signed with an EdDSA key, since the app is ad-hoc signed and code signing can't vouch for it.
The public key is `SUPublicEDKey` in `Info.plist`; the private key lives only in the
`SPARKLE_PRIVATE_KEY` repository secret (and its owner's Keychain). The release job signs
`CodexResetRadar.zip`, checks the signature against the public key the app ships with, and attaches
`appcast.xml` to the release, so the feed URL is the stable `releases/latest/download/appcast.xml`.
A missing or wrong key fails the job instead of publishing updates no app would accept.

## Consequences

- Sparkle downloads with `URLSession`, so updates carry no quarantine flag and install without a
  Gatekeeper prompt. Only the first install from the browser needs "Open Anyway".
- 0.7.0 and older can't update themselves: their users install the first Sparkle release by hand once.
- Losing the private key means shipping a release with a new public key that every user installs by hand.
- `sparkle:version` is `CFBundleVersion`, which the release job sets to the workflow run number, so
  it only ever grows.
