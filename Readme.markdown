# Countdown

Countdown is a macOS screen saver forked from [Motivation](https://github.com/soffes/Motivation). You can use it to count down to any date you want. (If you pick a date in the past, it will count up from that date instead.)

You can configure the date once you picked it in Screen Saver settings in System Settings.

[![Countdown Screen Saver](Countdown.gif)](Countdown.gif)

## Requirements

- macOS 13.0 or later
- Xcode 27 or later (Swift 6)

There is no prebuilt download: the maintainer of this fork does not have a
Developer ID certificate, so the bundle cannot be notarized and macOS would
block it for anyone else. Build it from source instead — it takes one command.

## Install

```bash
make install
```

That builds `Countdown.saver` and copies it to `~/Library/Screen Savers/`.

Then quit System Settings completely (⌘Q) and reopen it — it caches the list
of screen savers. Go to Wallpaper → Screen Saver, select **Countdown**, and
click **Options…** to pick your date.

If the saver still does not appear, log out and back in.

`make uninstall` removes it again.

## Building

```bash
make                  # -> build/Build/Products/Release/Countdown.saver
make clean
```

The Makefile uses `/Applications/Xcode.app` automatically, so it also works
when `xcode-select` points at the Command Line Tools. Building by hand works
too:

```bash
xcodebuild -project Countdown.xcodeproj -scheme Countdown -configuration Release \
  -derivedDataPath build build
```

## Development

Screen savers are hard to iterate on inside System Settings, so the project
ships a `Preview` target that hosts the same `CountdownView` in a normal
window:

```bash
make preview
```

Both targets compile the same files in `Countdown/Sources/`, so changes made
for the preview apply to the saver as well. The Preview app drives
`animateOneFrame()` with its own timer, since the screen saver host is not
available to do it.

See `CLAUDE.md` for a walkthrough of the architecture and the data flow
between the date picker, preferences, and the countdown view.

## License

MIT, originally by [Sam Soffes](https://github.com/soffes). See `LICENSE`.
