<!-- The title becomes the commit on main: use a Conventional Commit (feat:, fix:, docs:, ...). -->

## What and why

<!-- What changes, and the reason. -->

Closes #

## How it was verified

<!-- Commands you ran, what you tried in the bundled app, screenshots for visible changes. -->

## AI agents

<!-- Did you use mattpocock/skills (https://github.com/mattpocock/skills)? If not, say so, and
     name any other agent or tool that wrote part of the change. -->

## Checklist

- [ ] `swift build`, `swift format lint --strict --recursive Sources Tests` and `swift test` pass
- [ ] New or changed text the user sees is translated in every `.lproj` (or the PR says which are missing)
- [ ] `SPEC.md` is updated if behaviour changed
