#!/usr/bin/env zsh -f

# goes to: /usr/local/bin/timemachine-mount-run-unmount.sh

# Purpose: 	Once you set the DEVICE,
#			this script will mount your Time Machine drive,
#			run Time Machine,
#			and then unmount the drive
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-04-20

	## To find the device, mount the Time Machine drive and then run this command in Terminal:
	#
	#	mount | egrep '^/dev/' | sed -e 's# (.*#)#g' -e 's# on /# (/#g'
	#
	# and you will see a bunch of entries like this
	#
	#	/dev/disk2s1 (/Volumes/MBA-Clone - Data)
	#	/dev/disk3s5 (/Volumes/Storage)
	# 	/dev/disk4s6 (/Volumes/MBA-Clone)
	#
	# You need to set
	#
	#	DEVICE='/dev/disk3s5'
	#
	# or whatever is correct for your Time Machine drive

DEVICE='/dev/disk3s2'

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


	if [[ "$DEVICE" == "" ]]
	then
		echo "$NAME: the 'DEVICE' variable is not set" >>/dev/stderr
		exit 0
	fi

	diskutil mountDisk "$DEVICE"

fi

if [[ ! -d "$MNTPNT" ]]
then

	echo "$NAME: Failed to mount '$MNTPNT'." >>/dev/stderr
	exit 0
fi

TM_DRIVE_ID=$(tmutil destinationinfo | egrep '^ID  ' | sed 's#^ID  *: ##g' | head -1)

echo "$NAME: Starting backup at `timestamp`"

	# `caffeinate -i` is optional but keeps your Mac from sleeping
caffeinate -i tmutil startbackup --block --destination "$TM_DRIVE_ID"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Finished successfully at `timestamp`."

else

	echo "$NAME: Finished UN-successfully (Exit = $EXIT) at `timestamp`."

fi

while [[ -d "$MNTPNT" ]]
do

		# this will try to unmount the drive as long as it is mounted

	diskutil unmountDisk "$MNTPNT"

	sleep 10

done

exit 0
#EOF