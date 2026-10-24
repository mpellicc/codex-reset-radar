# Security policy

## Supported versions

Only the latest release gets security fixes. The app updates itself in place, so installed copies
receive fixes with the next release. Versions 0.7.0 and older can't update themselves: install the
[latest release](https://github.com/mpellicc/codex-reset-radar/releases/latest) by hand.

## Reporting a vulnerability

Don't open a public issue. Report it privately from the
[Security tab](https://github.com/mpellicc/codex-reset-radar/security/advisories/new)
with **Report a vulnerability**.

Include what you found, the steps to reproduce it and the app version. You'll get an answer within
7 days. Once a fix is released, the advisory is published with credit to you, unless you'd rather
stay anonymous.

## Scope

In scope: the app itself, including its in-place updates (update signing and the appcast), how it
fetches and reads data from codex-resets.com, and what it writes to the system log.

Out of scope: the codex-resets.com site and its data. Report those to the site.
