# Codex Reset Radar — v1 spec

A macOS menu bar app that tells you when a Codex usage reset has been announced.
It does one job: watch [codex-resets.com](https://codex-resets.com) and notify.

## Scope (v1)

- Notifies about announcements only. The AI watch forecast is shown in the panel, never notified.
- No backend, no accounts. Each Mac polls the public API directly.
- Distributed as an ad-hoc signed `.app` in a zip. No Apple Developer account,
  so colleagues approve it once via System Settings → Privacy & Security → Open Anyway.

## Data source

`GET https://codex-resets.com/api/v1/status` (free, no key, OpenAPI at `/api/openapi.json`).

Fields used:

- `data.scheduled_reset`: `id`, `reset_type` (`regular` | `banked`), `announced_at`,
  `scheduled_for` (nullable), `text`, `source.url`. Null when nothing is pending.
  A passed `scheduled_for` does not mean the reset happened.
- `data.latest_reset.announced_at`: the last reset that landed.
- `data.stats.avg_interval_days`.
- `data.active_watch`: `level` (`elevated` | `strong`), `reset_chance_percent` (nullable),
  `forecast_window`, `expires_at`, `text`, `source.url`. Null when there is no forecast. Decoded
  leniently: a watch that is missing, malformed or has an unknown level reads as none and never fails the poll.

Terms: the data must be credited with a link to codex-resets.com wherever it is shown.

**Updates.** [Sparkle](https://sparkle-project.org) reads the appcast at
`https://github.com/mpellicc/codex-reset-radar/releases/latest/download/appcast.xml` once a day in the
background and when the user clicks "Check for Updates…". A newer build (by `CFBundleVersion`) is offered
in Sparkle's standard window with its release notes; installing it replaces the app in place and
relaunches it. Updates must carry a valid EdDSA signature for the `SUPublicEDKey` in `Info.plist`.
Run outside the `.app` (`swift run`) there is no feed, so the updater doesn't start.
See [ADR 0001](docs/adr/0001-update-in-place-with-sparkle.md).

## Behaviour

**Polling.** On launch, every 15 minutes, after the Mac wakes, when the network comes back
(at most one such refresh per 30 seconds), and on "Refresh".
Sends `If-None-Match` with the last ETag. On HTTP 429, or 503 with `Retry-After`, polls are
skipped until the time the header gives (seconds or HTTP-date, at most 24 hours ahead), then
retried; a 429 without the header waits for the next regular poll. Errors are shown in the
panel as short messages (offline, timeout, server trouble, rate limited with the retry time,
unexpected response) and retried on the next poll; they never notify.

**Notification.** Sent when `scheduled_reset` has a non-null `scheduled_for` in the
future and either its `id` was never notified, or it was notified with a different
`scheduled_for` (title then says "rescheduled"). Notified `id → scheduled_for` pairs
are kept in `UserDefaults`, capped at 50. Clicking the notification opens the source post.

On first launch nothing has been notified yet, so if a dated reset is already pending the user
gets its notification right away. This is intended: a colleague who installs the app
mid-announcement should hear about it.

A second notification, "Codex reset landed" (or "Codex banked reset landed"), is sent when
`latest_reset.id` changes to a new id. That includes a surprise reset that was never announced.
The last seen `latest_reset.id` is kept in `UserDefaults`, so it is sent once per id and survives
relaunches. The first id ever seen is recorded without notifying: it is history, not news. A
`scheduled_reset` that clears with no new `latest_reset` was called off and is dropped silently.
Clicking the notification opens codex-resets.com, since `latest_reset` has no post URL.

A reminder, "Codex reset in 15 minutes", is sent the lead time before the `scheduled_for` of a
pending reset. The lead time is a setting: 5, 15, 30 or 60 minutes, 15 by default (the text follows it,
"Codex reset in 30 minutes"). It is kept in `UserDefaults` (`reminderLeadMinutes`; a missing or unknown
value reads as 15) and is chosen from a picker on the Reminder row. Changing it replaces the pending
reminder at once, like toggling Reminder. It is scheduled with the system (a calendar-triggered
notification request) so it fires even if no poll happens near the time. A reschedule replaces it,
so it fires once per `id` and `scheduled_for`. It is removed when the reset lands or is called off.
It is skipped when the reset is announced at or inside the lead time: the announcement covers it.
Clicking the reminder opens the source post.

**Notification switches.** Each kind can be turned off on its own: **Announced** ("reset announced"
and "rescheduled"), **Reminder** ("in N minutes") and **Landed** ("reset landed"). All three are on by
default. They are kept in `UserDefaults` (`notifyAnnounced`, `notifyReminder`, `notifyLanded`; a missing
key reads as on) and apply at once, without a restart. A switched-off kind is never sent, but the
trackers keep recording what they see (the notified pairs and the last seen `latest_reset.id`), so
switching it back on does not send what was skipped in the meantime. Turning Reminder off removes the
scheduled reminder request; turning it back on schedules it again for the pending dated reset right away,
not at the next poll. The menu bar countdown and the panel's reset details are not affected.

**Menu bar.** Radar icon: a custom SF Symbol with its rings and needle on separate layers, matching
the system's menu bar weight. When a dated reset is pending, the icon is followed by a
countdown: `45m`, `1h 59m`, `9h`, `3d`, or `due` once the time has passed. After 2 consecutive failed
polls (being offline counts) the icon becomes a slashed antenna, until the next successful
poll; the countdown stays next to it. VoiceOver reads the item as a sentence, for example
"Codex Reset Radar, reset in 9 hours", "…, reset due", "…, no reset announced" or "…, offline".
Clicking the item opens the panel under it, on the display that was clicked; Escape, a click elsewhere
or another click on the item closes it. The panel never takes focus from the app in front.

**Panel.**

- Notifications off: when notification authorization is denied, or allowed with alerts disabled,
  a warning "Notifications are off" with an "Open Notification Settings" button (the app's pane in
  System Settings) sits above everything else. The settings are read on launch and each time the
  panel opens, so the warning disappears once notifications are allowed again, without a restart.
  Nothing is shown before the user has been asked.
- Pending reset: type, local date and time, relative time, the announcement text,
  link to the post. With no date: "time not given yet". Past due: "waiting for it to land".
- Otherwise: "No reset announced".
- Forecast: the watch forecast in its own quieter section, labelled "Forecast" with a `sparkles` icon,
  all in the secondary colour and never in the pending-reset styling. It shows the level ("Elevated" or
  "Strong"), the chance when given ("40% chance"), `forecast_window` and the text as the API gives them,
  a "View source" link, and the line "AI guess, not an announcement". Hidden once `expires_at` has passed
  and whenever `scheduled_reset` is not null. It never notifies and never changes the menu bar icon or
  countdown, which keep meaning "announced".
- Last reset (relative) and average interval.
- Last checked time, error if the last poll failed.
- Launch at login toggle, then under a small "Notify me about" heading three checkboxes:
  Announced, Reminder (with its lead time picker), Landed (see Notification switches), then the "Data from codex-resets.com"
  link, and "Check for Updates…" with Quit.
- The toggle reads the login item status every time the panel opens. A failed change
  leaves the toggle at the real status and shows the error under it. When the item needs
  approval, the toggle stays on and a hint with a button opens System Settings → General → Login Items.
- When macOS has translocated the app (it runs from an `AppTranslocation` path, as when
  launched straight from Downloads), a warning says to quit, move the app to Applications and
  open it from there, and the toggle is disabled. The app only detects this; it doesn't move itself.

**Shortcuts and Siri.** One App Intent, **Get Next Codex Reset**, with the Siri phrases "When is the next
Codex reset in Codex Reset Radar", "Get the next Codex reset from Codex Reset Radar" and "Next Codex reset in
Codex Reset Radar". It returns the pending reset as a Codex Reset with Scheduled For (empty when no time is
given), Type (`regular` or `banked`, as the API sends it), Announcement (the post text) and Source (the post
URL), or nothing when no reset is pending. Siri and Shortcuts also say it in a sentence: when it is due and how
far away, "time not given yet", "hasn't landed yet" past due, or "No Codex reset is announced". It runs in the
app's process and reads the status the app already has; it never polls. Right after a launch it waits up to
10 seconds for the launch poll; if there is still no status (the poll failed), it fails with "hasn't loaded the
reset status yet". A status that is stale because later polls failed is still answered from.

## Tech

- Swift + SwiftUI, macOS 15+, Swift Package. Sparkle is its only dependency. The menu bar item is an
  `NSStatusItem` hosting SwiftUI, with an `NSPanel` for the panel, so symbol effects can animate
  (ADR 0003). The radar symbol is drawn by `scripts/menu-bar-symbol.py` into `Resources/Assets.xcassets`.
- `LSUIElement` (no Dock icon), `UserNotifications`, `SMAppService` for login item.
- `scripts/build-app.sh` builds a universal binary, assembles the `.app` with `Sparkle.framework`
  in `Contents/Frameworks`, compiles `Resources/Assets.xcassets` with `actool`, ad-hoc signs it and zips it into `dist/`. It builds with Swift Build
  (`--build-system swiftbuild`) and runs Xcode's `appintentsmetadataprocessor` and `appintentsnltrainingprocessor`
  to put the App Intents metadata (`Metadata.appintents`) and Siri phrase assets in the bundle, which plain
  SwiftPM doesn't do.
- `scripts/make-appcast.sh` signs the zip with the EdDSA private key and writes `dist/appcast.xml`;
  the release job attaches both to the GitHub release.

## Out of scope for v1

Notifying about the watch forecast, Slack, settings beyond launch at login and the notification switches.
