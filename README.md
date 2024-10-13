<img src="./icon.png" width="96" />

# macOS 15 screencapture nag remover

## Abstract

macOS 15 (Sequoia) introduced a new "security" feature which has frustrated many people, and insulted power users who prefer to have full control over their systems. The effect is nagging popups like the one below when apps that you have _already_ granted permission to try to capture your screen.

<img src="./sample.png" width="200" alt="nag image" />

> _Hey Apple, you forgot the “Always Allow” option!_

This script operates on the `~/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist` and sets the nag dates far in the future to avoid the popups from appearing.

## macOS 15.1 (currently in beta)

macOS 15.1 [introduces a new method][5] for suppressing these alerts across the board. This leverages a configuration profile which must be provisioned by an MDM server (e.g Jamf, Addigy, Mosyle etc). Apple unfortunately prohibits self-installing configuration profiles for certain TCC settings, ScreenCapture being one of them.

But don't despair, for self-managed Macs, the script also supports the standard method of individually setting MRU dates for each app (including macOS 15.1's new multi-keyed dict approach).

## Automatic Updates via LaunchAgent (required for smooth operation on 15.1)

macOS 15.1 made a change to replayd whereby upon each invocation of an app that requests ScreenCapture permission, the timestamp in the plist is overwritten with the current date/time. The net effect is that if you use an app once, and then don't use it again for >30 days, you will be nagged again, even if you had previously disabled the nag.

v1.3.0 of this script added a workaround for this: an option to install a LaunchAgent which runs every 24h and keeps the timestamps updated. This ensures that nags are kept hidden even as apps are used or if your system clock abruptly changes.

## Setup

1. Download the latest [release][4].
2. Open a Terminal and type `cd ~/Downloads` to navigate to the directory which should contain the file you just downloaded.
3. Remove the quarantine flag which probably exists on the file: `xattr -d com.apple.quarantine screencapture-nag-remover.sh`
4. Make the script executable: `chmod a+x screencapture-nag-remover.sh`
5. Place that `screencapture-nag-remover.sh` file somewhere in your `$PATH` (I suggest `/usr/local/bin` if you're unsure)
6. You are now ready to run the program!

## Use

Open a Terminal and run:

```
screencapture-nag-remover.sh
```

Full Disk Access is required so the protected plist file can be accessed. The program will check to ensure FDA has been granted. If it hasn't, the relevant System Settings panel will be opened.

With no arguments, it will iterate over any apps which have requested screencapture permissions and set the nag date for each to 100 years in the future. That _should_ prevent you from seeing the nag again.

> **N.B.** _If [life expectancy][1] increases dramatically over the next few years, you might need to run the app again in a decade or two._ 😉

There are also a few commandline arguments:

- `-h` shows the helptext
- `-r` will reveal the .plist responsible for these nags in Finder
- `-p` will print the **current** values without making any changes
- `-a <path|bundle_id>` creates a new entry in the plist for an app that you specify
- `--reset` initialize an empty ScreenCaptureApprovals.plist
- `--generate_profile` generate configuration profile for use with your MDM server
- `--profiles` opens Device Management in System Settings (to manage MDM profiles)
- `--install` installs a LaunchAgent (runs once per day) which ensures the nag dates are kept updated
- `--uninstall` removes the LaunchAgent

### Example of manually adding an app

macOS 15.0 (by specifying path)
```
screencapture-nag-remover.sh -a "/Applications/CleanShot X.app/Contents/MacOS/CleanShot X"
```

macOS 15.1 (using Bundle ID)
```
screencapture-nag-remover.sh -a cc.ffitch.shottr
```

If you encounter any problems, please file an [issue][3]. And in case anyone [@Apple][2] is reading this, please get rid of this bothersome "feature"...


[1]: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
[2]: https://github.com/apple
[3]: https://github.com/luckman212/screencapture-nag-remover/issues
[4]: https://github.com/luckman212/screencapture-nag-remover/releases
[5]: https://developer.apple.com/documentation/macos-release-notes/macos-15_1-release-notes#New-Features
