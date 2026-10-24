# Contributing to Codex Reset Radar

Thanks for wanting to help. Bug reports, ideas, translations and code are all welcome.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
To report a security problem, don't open an issue: follow [SECURITY.md](SECURITY.md).

## Issues

Open an [issue](https://github.com/mpellicc/codex-reset-radar/issues/new/choose) with the bug report or
feature request form. Every new issue is triaged before work on it starts.

Wrong or missing reset data comes from [codex-resets.com](https://codex-resets.com), not from this app.
Report it there.

## Before you write code

For anything bigger than a small fix, open an issue first, or comment on an existing one, and wait
for a reply. That saves you from building something that won't be merged.

[SPEC.md](../SPEC.md) describes how the app behaves and is the source of truth: a change in behaviour
updates it in the same pull request. [GLOSSARY.md](../GLOSSARY.md) defines the project's terms and
[docs/adr/](../docs/adr/) records past decisions. Read the ADR before reopening a decision it covers.

## Working with AI agents

The project is developed with AI coding agents using [mattpocock/skills](https://github.com/mattpocock/skills).
The repository is already set up for them: [AGENTS.md](../AGENTS.md) and [docs/agents/](../docs/agents/)
hold the issue tracker, triage labels and domain doc conventions the skills read.

You don't need them to contribute, but having them installed helps: your agent will follow the same
workflow, for example `/tdd` for changes and `/code-review` before opening the pull request. To install
them, run `npx skills@latest add mattpocock/skills`.

Whether you used them or not, say so in the pull request.

## Setup

You need macOS 15 or later, Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). CI uses Xcode 26.6. The README's [Build](../README.md#build) section
covers building the app bundle and running it in another language.

## Before opening a pull request

Run the same checks as CI:

```bash
swift build
swift format lint --strict --recursive Sources Tests
swift test
```

`swift format --in-place --recursive Sources Tests` fixes formatting.

- **Text the user sees or hears** goes through a lookup and gets a translation in every `.lproj`.
  Follow [docs/agents/localization.md](../docs/agents/localization.md). If you can't translate a
  string into a language, say so in the pull request.
- **Behaviour changes** update [SPEC.md](../SPEC.md).
- **Bug fixes and new behaviour** come with tests.

## Pull requests

Pull requests are squash-merged, and the title becomes the commit on `main`. It must be a
[Conventional Commit](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, ...), and a
check enforces it. release-please builds the version and changelog from these titles, so don't
bump versions, edit `CHANGELOG.md` or tag. See [Releasing](../README.md#releasing).

Keep one change per pull request and link the issue it closes. The template asks for the rest.

## License

Contributions are released under the project's [MIT License](../LICENSE).
