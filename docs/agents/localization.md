# Localization

The app ships English and Italian (more in #56). Every string a user can see or hear goes through a lookup in `Resources/<code>.lproj/Localizable.strings`. A string that skips the lookup shows in English in every language, and nothing warns you.

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
2. Add the key with its Italian value to `Resources/it.lproj/Localizable.strings`, in the section that matches where it shows (Panel, Notifications, VoiceOver, …). Add it to every other `.lproj` too. If you can't translate one, say so in the PR. Never leave it out silently.
3. `“%@”` and `Codex Reset Radar` stay untranslated.

Siri phrases for App Shortcuts (`AppShortcutsProvider`) are the exception: their keys are the English phrases with `${applicationName}` in place of `\(.applicationName)`, and they go in `Resources/<code>.lproj/AppShortcuts.strings`, not `Localizable.strings`. Keep `${applicationName}` in every translation.

## Checking

Extract the keys the compiler sees and compare them with each `.lproj`:

```bash
swift build -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc <dir>
```

Every extracted key except `“%@”` and `Codex Reset Radar` must have a value in every `.lproj`. A key that's in a `.lproj` but no longer extracted usually means a string lost its lookup. Look for a `String` that reaches `Text`.

Then run the built app in each language and look at what you changed:

```bash
"dist/Codex Reset Radar.app/Contents/MacOS/CodexResetRadar" -AppleLanguages '(it)'
```
