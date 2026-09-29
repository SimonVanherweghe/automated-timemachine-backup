#!/bin/zsh -f

# goes to: /usr/local/bin/timemachine-mount-run-unmount.sh

# Purpose: 	This script will mount your Time Machine drive,
#			run Time Machine,
#			and then unmount the drive
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-04-20
#
# The device is looked up by the Time Machine destination name on every run,
# because disk identifiers (disk5s1, disk5s2, ...) change after an erase or replug.

################################################################################################

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

STATUS=$(tmutil currentphase)

if [[ "$STATUS" != "BackupNotRunning" ]]
then
	echo "$NAME: Time Machine status is '$STATUS'. Should be 'BackupNotRunning'." >>/dev/stderr
	exit 0
fi

	# if you have multiple Time Machine destinations, this might not give you the right info
	# I'm assuming you only have one
TM_DRIVE_NAME=$(tmutil destinationinfo | egrep '^Name  ' | sed 's#^Name  *: ##g' | head -1)

MNTPNT="/Volumes/$TM_DRIVE_NAME"

if [[ -d "$MNTPNT" ]]
then

	echo "$NAME: '$MNTPNT' is already mounted".

else


	DEVICE=$(diskutil info "$TM_DRIVE_NAME" 2>/dev/null | awk '/Device Identifier:/ {print $3}')

	if [[ "$DEVICE" == "" ]]
	then
		echo "$NAME: could not find a disk for '$TM_DRIVE_NAME'. Is it connected?" >>/dev/stderr
		exit 1
	fi

		# an encrypted backup disk has to be unlocked first; the password is read from the login keychain
		# store it once with: security add-generic-password -s "$NAME" -a "<drive name>" -w
	if diskutil info "$DEVICE" | egrep -q '^ *Locked: *Yes'
	then
		PASSPHRASE=$(security find-generic-password -s "$NAME" -a "$TM_DRIVE_NAME" -w 2>/dev/null)

		if [[ "$PASSPHRASE" == "" ]]
		then
			echo "$NAME: '$TM_DRIVE_NAME' is encrypted, but no password was found in the keychain (service '$NAME', account '$TM_DRIVE_NAME')." >>/dev/stderr
			exit 1
		fi

		print -r -- "$PASSPHRASE" | diskutil apfs unlockVolume "$DEVICE" -stdinpassphrase

		unset PASSPHRASE
	fi

	[[ -d "$MNTPNT" ]] || diskutil mountDisk "$DEVICE"

fi

if [[ ! -d "$MNTPNT" ]]
then

	echo "$NAME: Failed to mount '$MNTPNT'." >>/dev/stderr
	exit 0
fi

TM_DRIVE_ID=$(tmutil destinationinfo | egrep '^ID  ' | sed 's#^ID  *: ##g' | head -1)

	# `tmutil startbackup --block` exits 0 even when backupd refuses the backup
	# (e.g. disk full), so compare the latest backup before and after instead
BEFORE=$(tmutil latestbackup 2>/dev/null)

LOG_START=$(strftime "%Y-%m-%d %H:%M:%S" "$EPOCHSECONDS")

echo "$NAME: Starting backup at `timestamp`"

	# `caffeinate -i` is optional but keeps your Mac from sleeping
caffeinate -i tmutil startbackup --block --destination "$TM_DRIVE_ID"

EXIT="$?"

AFTER=$(tmutil latestbackup 2>/dev/null)

if [[ "$EXIT" == "0" && -n "$AFTER" && "$AFTER" != "$BEFORE" ]]
then
	echo "$NAME: Finished successfully at `timestamp`."

	RESULT=0

else

		# full path: `log` is a zsh builtin
	REASON=$(/usr/bin/log show --start "$LOG_START" --style compact \
		--predicate 'subsystem == "com.apple.TimeMachine" AND eventMessage CONTAINS "Backup failed"' \
		2>/dev/null | grep 'Backup failed' | tail -1 | sed 's#.*Backup failed: ##')

	[[ "$REASON" == "" ]] && REASON="no new backup was created"

	echo "$NAME: Finished UN-successfully (Exit = $EXIT, Reason = $REASON) at `timestamp`." >>/dev/stderr

	osascript -e "display notification \"$REASON\" with title \"Time Machine backup failed\""

	RESULT=1

fi

while [[ -d "$MNTPNT" ]]
do

		# this will try to unmount the drive as long as it is mounted

	diskutil unmountDisk "$MNTPNT"

	sleep 10

done

exit "$RESULT"
#EOF