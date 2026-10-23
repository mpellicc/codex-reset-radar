# Menu bar item as an NSStatusItem with a layered symbol

The menu bar item is an `NSStatusItem` whose button hosts a live SwiftUI view, and the panel is our
own `NSPanel` hosting `RadarPanel`. It replaces SwiftUI's `MenuBarExtra`. The radar is a custom SF
Symbol in `Resources/Assets.xcassets` instead of a template PNG.

`MenuBarExtra` draws its label once into a static image (the status bar button holds no view, only an
image), so symbol effects never animate in it. The menu bar animations in #69 need the radar's parts
to move on their own: the needle sweeping, the rings lighting from the centre. A status item that
hosts a real view runs them, on every display.

The symbol is a variable template (Ultralight, Regular and Black) drawn by
`scripts/menu-bar-symbol.py`, which writes the layers and their annotations: the needle and the outer
ring, which is open around the needle's blip, rotate together around the radar's centre, so the opening
reads as the blip's halo; the dot and rings carry variable-colour thresholds from the centre out.
Xcode compiles the catalog with the rest of the app's resources (ADR 0003).

## Consequences

- Opening, placing and closing the panel is our code: it opens under the item (under the copy that
  was clicked, with several displays), floats without activating the app, and closes on Escape, a
  click elsewhere, or a second click on the item.
- The label's width and the item's VoiceOver label are set from the model by hand.
- SwiftUI keeps an empty `Settings` scene, since an `App` needs one; a Settings window (#74) can fill it.
- Changing the radar means running the script and committing the SVG it writes, not editing the SVG
  by hand. The SF Symbols app opens the SVG to preview it.
