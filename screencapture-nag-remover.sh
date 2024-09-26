#!/bin/bash

PLIST="$HOME/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist"
MDM_PROFILE='/private/tmp/15.1_DisableScreenCaptureAlerts.mobileconfig'

IFS='.' read -r MAJ MIN _ < <(/usr/bin/sw_vers --productVersion)
if (( MAJ < 15 )); then
	echo >&2 "this tool requires macOS 15 (Sequoia)"
	exit
fi

_openDeviceManagement() {
	open 'x-apple.systempreferences:com.apple.preferences.configurationprofiles'
}

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

_installMdmProfile() {
cat <<EOF >"$MDM_PROFILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadIdentifier</key>
			<string>com.apple.sequoia.stop.nagging</string>
			<key>PayloadType</key>
			<string>com.apple.TCC</string>
			<key>PayloadUUID</key>
			<string>D6D8CA6B-1958-4CD7-92F8-D2F9CC34A4A4</string>
			<key>com.apple.TCC.configuration-profile-policy</key>
			<dict>
				<key>ScreenCapture</key>
				<dict>
					<key>forceBypassScreenCaptureAlert</key>
					<true/>
				</dict>
			</dict>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>Disable ScreenCapture Alerts</string>
	<key>PayloadIdentifier</key>
	<string>com.apple.sequoia.stop.nagging</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>E6056B28-1B01-4EED-8F41-859E6C02E688</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
EOF
open "$MDM_PROFILE"
cat <<EOF

The Device Management panel from System Settings should now open.
Double-click on the 'Disable ScreenCapture Alerts' profile to install and activate it.

EOF
sleep 1
_openDeviceManagement
}

case $1 in
	-h|--help)
		/bin/cat <<-EOF
		${0##*/} [args]
		    -r,--reveal       show the related plist in Finder
		    -p,--print        print current values
		    -a,--add <path>   manually create an entry (supply full path)
		    --profile         opens Device Management in System Settings
		EOF
		exit
		;;
	--profile) _openDeviceManagement; exit;;
esac

if (( MAJ == 15 )) && (( MIN > 0 )); then
	if ! profiles list -type configuration | grep -q com.apple.sequoia.stop.nagging ; then
		cat <<-EOF
		==============================================================================
		macOS 15.1 offers an official method for suppressing the ScreenCapture alerts
		The mechanism used is a Configuration Profile (also known as an MDM profile)
		==============================================================================
		EOF
		read -r -p "Would you like to install this profile (Y/n)? " ANSWER
		[[ -z $ANSWER ]] && ANSWER='y'
		case $ANSWER in
			[yY]) _installMdmProfile; exit 0;;
		esac
	else
		cat <<-EOF
		The Configuration Profile to suppress the ScreenCapture alerts is installed.
		Remove it if you'd like to use this tool in legacy mode.
		EOF
		exit 0
	fi
fi

if ! /usr/bin/touch "$PLIST" 2>/dev/null; then
	echo >&2 "Full Disk Access is required${TERM_PROGRAM:+ for $TERM_PROGRAM}"
	open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'
	exit 1
fi

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
