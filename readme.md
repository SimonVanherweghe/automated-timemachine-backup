# Automate Time Machine Backups

## Scenario

I have a USB disk for Time Machine backups that is plugged in to my external monitor USB hub. Every time I hook up my computer to the screen, that volume is mounted. But I always forget to unmount it when I unplug my computer from the screen. This will lead to 💩 sooner or later.

## Goals

- Prevent the disk from being mounted when I plug in my computer to the screen
- At a certain time of day (night), mount the disk and start a Time Machine backup, unmount when ready.

## Locations

- time-machine-mount-run-unmount.sh: /usr/local/bin/timemachine-mount-run-unmount.sh
- fstab: /etc/fstab
- com.donebysimon.timemachine-mount-run-unmount.plist: ~/Library/LaunchAgents/com.donebysimon.timemachine-mount-run-unmount.plist

## Gotchas

- a plist file doesn't seem to like newlines inside tags. Watch out with a xml formatter for that one.
- You can test a plist file with 'plutil'
- `launchctl load` seems to be deprecated
- Got it finally up and running with <https://www.soma-zone.com/LaunchControl/>

## Resources

<https://talk.macpowerusers.com/t/any-way-to-automate-a-time-machine-backup-mount-backup-unmount/16758/10>
<https://gist.github.com/tjluoma/8c8a05c217daa2de085c9c07531805b3>

<https://akrabat.com/prevent-an-external-drive-from-auto-mounting-on-macos/>
