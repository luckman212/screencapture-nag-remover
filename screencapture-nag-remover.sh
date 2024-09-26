#!/bin/bash

IFS='.' read -r MAJ MIN DOT < <(/usr/bin/sw_vers --productVersion)
if [[ $MAJ != 15 ]]; then
	echo >&2 "this tool requires macOS 15 (Sequoia)"
	exit
fi

PLIST="$HOME/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist"

if ! /usr/bin/touch "$PLIST" 2>/dev/null; then
	echo >&2 "Full Disk Access is required${TERM_PROGRAM:+ for $TERM_PROGRAM}"
	open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'
	exit 1
fi

_createPlist() {
	cat <<-EOF >"$PLIST"
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	</dict>
	</plist>
	EOF
}

_bounce_daemons() {
	/usr/bin/killall -HUP replayd
	/usr/bin/killall -u "$USER" cfprefsd
}

_nagblock() {
	[[ -n $1 ]] || { echo >&2 "supply complete pathname to the binary inside the app bundle"; return 1; }
	[[ -e $1 ]] || { echo >&2 "$1 does not exist"; return 1; }
	IFS='/' read -ra PARTS <<< "$1"
	for p in "${PARTS[@]}"; do
		if [[ $p == *.app ]]; then
			echo >&2 "disabling nag for $p"
			/usr/bin/defaults write "$PLIST" "$1" -date "$FUTURE"
			return 0
		fi
	done
	return 1
}

case $1 in
	-h|--help)
		/bin/cat <<-EOF
		${0##*/} [args]
		    -r,--reveal       show the related plist in Finder
		    -p,--print        print current values
		    -a,--add <path>   manually create an entry (supply full path)
		EOF
		exit
		;;
esac

[[ -e $PLIST ]] || _createPlist
FUTURE=$(/bin/date -j -v+100y +"%Y-%m-%d %H:%M:%S +0000")

case $1 in
	-r|--reveal) /usr/bin/open -R "$PLIST"; exit;;
	-p|--print) /usr/bin/plutil -p "$PLIST"; exit;;
	-a|--add)	_nagblock "$2"; _bounce_daemons; exit;;
	-*) echo >&2 "invalid arg: $1"; exit 1;;
esac

while read -r APP_PATH ; do
	_nagblock "$APP_PATH"
done < <(/usr/bin/plutil -convert xml1 -o - -- "$PLIST" | /usr/bin/sed -n "s/.*<key>\(.*\)<\/key>.*/\1/p")

#bounce daemons so changes are detected
_bounce_daemons
