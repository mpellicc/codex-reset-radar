# Codex Reset Radar

A macOS menu bar app that watches codex-resets.com and tells you when a Codex usage reset is coming and when it lands.

## Language

**Reset**:
An event where OpenAI restores Codex usage limits for everyone.
_Avoid_: Refill, limit reset

**Banked reset**:
A reset of the `banked` type, as opposed to a regular one.

**Announcement**:
A public post saying a reset is coming, optionally with the time it is scheduled for.
_Avoid_: Notice, alert

**Pending reset**:
A reset that has been announced and has neither landed nor been called off.
_Avoid_: Upcoming reset, scheduled reset (when speaking about the domain, not the API field)

**Due**:
The state of a pending reset whose scheduled time has passed but which has not landed yet. A passed time does not mean the reset happened.
_Avoid_: Overdue, expired

**Landed**:
A reset has landed when it has actually taken effect. Seen as the latest reset changing to a new one, whether or not it was announced first.
_Avoid_: Happened, completed, applied

**Called off**:
A pending reset that disappears without landing.
_Avoid_: Cancelled

**Reminder**:
The notification sent the **lead time** (5, 15, 30 or 60 minutes, 15 by default) before a pending reset's scheduled time.

**Watch forecast**:
The source's AI-generated guess that a reset may be coming, without an announcement.
_Avoid_: Prediction
