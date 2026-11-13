# Countdown

Countdown is a macOS screen saver forked from [Motivation](https://github.com/soffes/Motivation). You can use it to countdown to any date you want. (If you pick a date in the past, it will count up from that date instead.)

You can configure the date once you picked it in Screen Saver settings in System Settings.

[![Countdown Screen Saver](Countdown.gif)](https://github.com/soffes/Countdown/releases)


## Requirements

- macOS 13.0 or later
- Xcode 27 or later (Swift 6)


## Building

```bash
xcodebuild -project Countdown.xcodeproj -scheme Countdown -configuration Release \
  -derivedDataPath build build
```

The screen saver is written to `build/Build/Products/Release/Countdown.saver` and is ad-hoc signed.

If `xcodebuild` reports that it requires Xcode, point it at your installation:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```


## Installing

```bash
cp -R build/Build/Products/Release/Countdown.saver ~/Library/Screen\ Savers/
```

Then quit System Settings completely (⌘Q) and reopen it, otherwise it keeps showing the cached bundle. Go to Wallpaper → Screen Saver, select **Countdown**, and click **Options…** to pick your date.

If the saver still does not appear, run `killall legacyScreenSaver` or log out and back in.


## Development

Screen savers are hard to iterate on inside System Settings, so the project ships a `Preview` target that hosts the same `CountdownView` in a normal window:

```bash
xcodebuild -project Countdown.xcodeproj -scheme Preview -configuration Debug \
  -derivedDataPath build build
open build/Build/Products/Debug/Preview.app
```

Both targets compile the same files in `Countdown/Sources/`, so changes made for the preview apply to the saver as well. The Preview app drives `animateOneFrame()` with its own timer, since the screen saver host is not available to do it.

See `CLAUDE.md` for a deeper walkthrough of the architecture and the data flow between the date picker, preferences, and the countdown view.

