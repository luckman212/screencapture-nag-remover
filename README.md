<img src="./icon.png" width="96" />

# macOS 15 screencapture nag remover

## Abstract

macOS 15 (Sequoia) introduced a new "security" feature which has frustrated many people, and insulted power users who prefer to have full control over their systems. The effect is nagging popups like the one below when apps that you have already granted permission to try to record your screen.

<img src="./sample.png" width="200" alt="nag image" />

> _Hey Apple, you forgot the “Always Allow” option!_

This script operates on the `~/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist` and sets the nag dates far in the future to avoid the popups from appearing.

## macOS 15.1 (currently in beta)

macOS 15.1 has introduced a new method for suppressing these alerts across the board. This requires an MDM profile (typically something provided by Jamf, Addigy, Mosyle etc). A manually generated profile can be installed without requiring the Mac to be MDM-joined.

When run without arguments on 15.1 or higher, the script will offer to install this profile for you.

## How to use

Download the latest [release][4] and place the script in your `$PATH` (I suggest `/usr/local/bin` if you're unsure).

Then run the program from a shell (Full Disk Access is required, and the program will check to ensure FDA has been granted. If it hasn't, the relevant System Settings panel will be opened).

With no arguments, it will iterate over any apps which have requested screencapture permissions and set the nag date for each to 100 years in the future. That _should_ prevent you from seeing the nag again.

> **N.B.** _If [life expectancy][1] increases dramatically over the next few years, you might need to run the app again in a decade or two._ 😉

There are also a few commandline arguments:

- `-r` will reveal the .plist responsible for these nags in Finder
- `-p` will print the **current** values without making any changes
- `-a <path|bundle_id>` creates a new entry in the plist for an app that you specify
- `--profile` opens Device Management in System Settings (to manage MDM profiles)
- `--reset` initialize an empty ScreenCaptureApprovals.plist

### Example of manually adding an app

macOS 15.0
```
screencapture-nag-remover.sh -a "/Applications/CleanShot X.app/Contents/MacOS/CleanShot X"
```

macOS 15.1
```
screencapture-nag-remover.sh -a cc.ffitch.shottr
```

If you encounter any problems, please file an [issue][3]. And in case anyone [@Apple][2] is reading this, please get rid of this bothersome "feature"...


[1]: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
[2]: https://github.com/apple
[3]: https://github.com/luckman212/screencapture-nag-remover/issues
[4]: https://github.com/luckman212/screencapture-nag-remover/releases
