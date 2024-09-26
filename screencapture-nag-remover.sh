#!/bin/bash

IFS='.' read -r MAJ MIN DOT < <(/usr/bin/sw_vers --productVersion)
if [[ $MAJ != 15 ]]; then
	echo >&2 "this tool requires macOS 15 (Sequoia)"
	exit
fi

PLIST="$HOME/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist"
FUTURE=$(/bin/date -j -v+100y +"%Y-%m-%d %H:%M:%S +0000")

case $1 in
	-h|--help)
		/bin/cat <<-EOF
		${0##*/} [args]
		    -r,--reveal    show the related plist in Finder
		    -p,--print     print current values
		EOF
		exit
		;;
	-r|--reveal) /usr/bin/open -R "$PLIST"; exit;;
	-p|--print) /usr/bin/plutil -p "$PLIST"; exit;;
esac

while read -r APP_PATH ; do
	IFS='/' read -ra PARTS <<< "$APP_PATH"
	for p in "${PARTS[@]}"; do
		if [[ -e $APP_PATH ]] && [[ $p == *.app ]]; then
			echo 1>&2 "disabling nag for $p"
			/usr/bin/defaults write "$PLIST" "$APP_PATH" -date "$FUTURE"
			break
		fi
	done
done < <(/usr/bin/plutil -convert xml1 -o - -- "$PLIST" | /usr/bin/sed -n "s/.*<key>\(.*\)<\/key>.*/\1/p")

#bounce daemons so changes are detected
/usr/bin/killall -HUP replayd
/usr/bin/killall -u "$USER" cfprefsd
