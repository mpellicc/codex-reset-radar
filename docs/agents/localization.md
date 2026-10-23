# Localization

The app ships English, Italian (`it`), Spanish (`es`), French (`fr`), German (`de`) and Simplified Chinese (`zh-Hans`). Every string a user can see or hear goes through a lookup in `Resources/<code>.lproj/Localizable.strings`. A string that skips the lookup shows in English in every language, and nothing warns you.

## Writing a string

Keys are the English text itself. There's no separate key scheme.

| Where the text is | Write | Not |
|---|---|---|
| A literal straight in a SwiftUI view | `Text("No reset announced")`, `Button("Quit")`, `Toggle("…", isOn:)` | — |
| A title passed into your own view | `init(_ title: LocalizedStringKey, …)` and `Text(title)` | `title: String`. `Text(someString)` renders verbatim, with no lookup (this is how #55 broke the Italian switch labels) |
| A string built in code (model, `RadarCore`, notifications, VoiceOver, errors) | `String(localized: "Codex \(noun) landed")` | `"…"` plain, or `NSLocalizedString` |
| Choosing between literals in a view | `Text(cond ? LocalizedStringKey("A") : "B")` | a ternary of plain `String`s |
| The same English word with two meanings | `String(localized: "spoken-due", defaultValue: "due")` | reusing the key, which forces one translation on both |
| Text from the API (announcement `text`, forecast `text`) | interpolate it, as in `Text("“\(reset.text)”")` (key `“%@”`, never translated), or `Text(verbatim: value)` | `Text(LocalizedStringKey(value))`. Posts stay in their original wording |

Interpolations become format specifiers in the key: `"in \(x)"` is the key `"in %@"`, an `Int` is `%lld`, a `Double` with `.formatted(…)`/`%.1f` keeps its specifier. The translation must keep the same specifiers.

Counts: write one key for 1 and one for the rest (`"1 minute"` / `"\(m) minutes"`), as `Format.swift` does. Counts never reach 0. A language that needs more plural forms would need a stringsdict (see #56).

Dates, times and relative times come from `Date.formatted` and `RelativeDateTimeFormatter`, which already follow the app's language. Don't format them by hand.

The menu bar countdown stays terse in every language (`45m`, `1h 59m`, `3d`): it sits in the menu bar.

## Adding a string

1. Write it as in the table above.
2. Add the key with its translation to every `Resources/<code>.lproj/Localizable.strings`, in the section that matches where it shows (Panel, Notifications, VoiceOver, …). If you can't translate one, say so in the PR. Never leave it out silently.
3. `“%@”` and `Codex Reset Radar` stay untranslated.

Siri phrases for App Shortcuts (`AppShortcutsProvider`) are the exception: their keys are the English phrases with `${applicationName}` in place of `\(.applicationName)`, and they go in `Resources/<code>.lproj/AppShortcuts.strings`, not `Localizable.strings`. Keep `${applicationName}` in every translation.

## Terminology

Don't invent product or system terms. Take them from the source the user already sees:

- **Codex terms** (reset, banked reset, usage limits, …): use the wording of OpenAI's Codex app in that language. Its translations ship inside `/Applications/Codex.app/Contents/Resources/app.asar`, one file per locale under `webview/assets/` (`it-IT-….js`, `de-DE-….js`, `zh-CN-….js`), as `` "<key>":`value` `` pairs. The English source for a key is its `defaultMessage` elsewhere in the asar. The help center (help.openai.com) blocks direct fetches and sometimes disagrees with the app; the app wins.
- **macOS labels** (System Settings, Login Items, Notifications, …): use Apple's own wording, because the user has to find that label on their Mac. Read it from the localized tables inside macOS (for example `/System/Library/ExtensionKit/Extensions/LoginItems.appex`) or Apple's localized support pages. Here Apple wins over the Codex app (German macOS says *Mitteilungen*, the Codex app *Benachrichtigungen*).
- **Numbers and units**: follow what `Date.formatted`, `DateComponentsFormatter` and `RelativeDateTimeFormatter` produce in that language (for example no space in Chinese: `45分钟`), except the terse menu bar countdown.

Current reset nouns:

| | reset | banked reset |
|---|---|---|
| `it` | reimpostazione | reimpostazione accumulata |
| `es` | restablecimiento | restablecimiento acumulado |
| `fr` | réinitialisation | réinitialisation en réserve |
| `de` | Zurücksetzung | gesammelte Zurücksetzung |
| `zh-Hans` | 重置 | 储备重置 |

When a noun's gender changes, check every string that interpolates it (`%@`) for agreement.

## Adding a language

1. Copy `Resources/it.lproj/Localizable.strings` and `AppShortcuts.strings` to `Resources/<code>.lproj/` and translate the values. Keys stay in English.
2. Add `<code>` to `CFBundleLocalizations` in `Resources/Info.plist`. Edit the file by hand: `PlistBuddy` reorders it and drops the `x-release-please-version` comment.
3. Take terms from the sources in Terminology, and list them in the PR.
4. A language that needs more plural forms than one/other needs a stringsdict (see Writing a string).
5. A native speaker should review the strings before release.

## Checking

Extract the keys the compiler sees and compare them with each `.lproj`:

```bash
swift build -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc <dir>
```

The output is one `.stringsdata` file (JSON) per source file; the keys are under `tables.Localizable[].key`. An incremental build may skip files it doesn't recompile, so use a fresh `--build-path` (for example `swift build --build-path /tmp/strings-build …`).

Every extracted key except `“%@”` and `Codex Reset Radar` must have a value in every `.lproj`. A key that's in a `.lproj` but no longer extracted usually means a string lost its lookup. Look for a `String` that reaches `Text`.

Then run the built app in each language and look at what you changed:

```bash
"dist/Codex Reset Radar.app/Contents/MacOS/CodexResetRadar" -AppleLanguages '(it)'
```
