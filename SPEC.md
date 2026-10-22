# Codex Reset Radar — v1 spec

A macOS menu bar app that tells you when a Codex usage reset has been announced.
It does one job: watch [codex-resets.com](https://codex-resets.com) and notify.

## Scope (v1)

- Announcements only. The AI "watch" forecast from the API is ignored.
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

Terms: the data must be credited with a link to codex-resets.com wherever it is shown.

**Update check.** On launch and then once a day the app asks
`GET https://api.github.com/repos/mpellicc/codex-reset-radar/releases/latest` for the newest
release. Its `tag_name` (without the leading `v`) is compared with the app's
`CFBundleShortVersionString` as `MAJOR.MINOR.PATCH`. Versions that don't have that shape, such as
`dev` when run outside the `.app` or a prerelease suffix, never offer an update. A failed check
is silent. It never notifies, downloads or installs anything.

## Behaviour

**Polling.** On launch, every 15 minutes, after the Mac wakes, when the network comes back
(at most one such refresh per 30 seconds), and on "Refresh".
Sends `If-None-Match` with the last ETag. On HTTP 429, or 503 with `Retry-After`, polls are
skipped until the time the header gives (seconds or HTTP-date, at most 24 hours ahead), then
retried; a 429 without the header waits for the next regular poll. Errors are shown in the
panel as short messages (offline, timeout, server trouble, rate limited with the retry time,
unexpected response) and retried on the next poll; they never notify.

**Notifications.** Announcements, landings and reminders use separate notification threads
(`reset-announcements`, `reset-landings`, `reset-reminders`) for macOS automatic grouping.
They also have separate request identifiers, so a landing never replaces its announcement.
Reschedules stay in the announcement thread. The existing persisted announcement pairs and
last seen landing id are reused across upgrades and relaunches; the grouping adds no new state.

**Announcement notification.** "Codex reset announced" (or "Codex banked reset announced")
is sent when `scheduled_reset` has a non-null `scheduled_for` in the
future and either its `id` was never notified, or it was notified with a different
`scheduled_for` (title then says "rescheduled"). Notified `id → scheduled_for` pairs
are kept in `UserDefaults`, capped at 50. The subtitle explicitly says "Scheduled for" with the
local date/time and relative time; the body contains the announcement text. It reports a plan,
not a reset that has landed. Clicking the notification opens the source post.

On first launch nothing has been notified yet, so if a dated reset is already pending the user
gets its notification right away. This is intended: a colleague who installs the app
mid-announcement should hear about it.

**Landing notification.** "Codex reset landed" (or "Codex banked reset landed") is sent when
`latest_reset.id` changes to a new id. That includes a surprise reset that was never announced.
The last seen `latest_reset.id` is kept in `UserDefaults`, so it is sent once per id and survives
relaunches. The first id ever seen is recorded without notifying: it is history, not news. A
`scheduled_reset` that clears with no new `latest_reset` was called off and is dropped silently.
The subtitle says "Reset confirmed" and the body says "The reset has landed. Your usage limits
are back." Only a new latest reset confirms a landing; a passed scheduled time does not.
Clicking the notification opens codex-resets.com, since `latest_reset` has no post URL.

**Reminder notification.** "Codex reset in 15 minutes" is sent 15 minutes before the `scheduled_for` of a
pending reset. The lead time is fixed. It is scheduled with the system (a calendar-triggered
notification request) so it fires even if no poll happens near the time. A reschedule replaces it,
so it fires once per `id` and `scheduled_for`. It is removed when the reset lands or is called off.
It is skipped when the reset is announced less than 15 minutes ahead: the announcement covers it.
Clicking the reminder opens the source post.

**Menu bar.** Radar icon. When a dated reset is pending, the icon is followed by a
countdown: `45m`, `1h 59m`, `9h`, `3d`, or `due` once the time has passed. After 2 consecutive failed
polls (being offline counts) the icon becomes a slashed antenna, until the next successful
poll; the countdown stays next to it. VoiceOver reads the item as a sentence, for example
"Codex Reset Radar, reset in 9 hours", "…, reset due", "…, no reset announced" or "…, offline".

**Panel.**

- Notifications off: when notification authorization is denied, or allowed with alerts disabled,
  a warning "Notifications are off" with an "Open Notification Settings" button (the app's pane in
  System Settings) sits above everything else. The settings are read on launch and each time the
  panel opens, so the warning disappears once notifications are allowed again, without a restart.
  Nothing is shown before the user has been asked.
- Pending reset: type, local date and time, relative time, the announcement text,
  link to the post. With no date: "time not given yet". Past due: "waiting for it to land".
- Otherwise: "No reset announced".
- Last reset (relative) and average interval.
- Last checked time, error if the last poll failed.
- When the update check found a newer release: "Version X available — Download", linking to
  the release page.
- Launch at login toggle, "Data from codex-resets.com" link, Quit.
- The toggle reads the login item status every time the panel opens. A failed change
  leaves the toggle at the real status and shows the error under it. When the item needs
  approval, the toggle stays on and a hint with a button opens System Settings → General → Login Items.
- When macOS has translocated the app (it runs from an `AppTranslocation` path, as when
  launched straight from Downloads), a warning says to quit, move the app to Applications and
  open it from there, and the toggle is disabled. The app only detects this; it doesn't move itself.

## Tech

- Swift + SwiftUI `MenuBarExtra`, macOS 13+, Swift Package with no dependencies.
- `LSUIElement` (no Dock icon), `UserNotifications`, `SMAppService` for login item.
- `scripts/build-app.sh` builds a universal binary, assembles the `.app`,
  ad-hoc signs it and zips it into `dist/`.

## Out of scope for v1

Watch forecast, Slack, installing updates (the app only checks for them), settings beyond
launch at login.
