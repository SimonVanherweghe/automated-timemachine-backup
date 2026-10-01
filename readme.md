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

## Commands

Find the UUID of your Time Machine disk:

```bash
diskutil list
```

or

```bash
mount | egrep '^/dev/' | sed -e 's# (.*#)#g' -e 's# on /# (/#g'
```

test run:

```bash
/usr/local/bin/timemachine-mount-run-unmount.sh
```

## Encrypted backup disk

If "Encrypt backups" is on, the script unlocks the disk with a password from your login keychain. Store it once (it prompts for the password):

```bash
security add-generic-password -s timemachine-mount-run-unmount -a 2TBSanDsik -w
```

⚠️ This only works when you run the script from Terminal. With an encrypted disk I ran into two problems, so I went back to an unencrypted disk:

- The scheduled (launchd) run can't unlock the disk: `Error unlocking APFS Volume: This operation is restricted by Sandbox (-69464)`. It would need Full Disk Access for `/bin/zsh`.
- The `noauto` line in fstab doesn't stop the password popup when you plug in the disk. Entering the password mounts it.

When you add the disk in Time Machine, "Encrypt Backup" is on by default.

## Troubleshooting

"Total copied: 0.00 MB" means Time Machine refused the backup (`tmutil startbackup` still exits 0). Find the reason in the logs (use `/usr/bin/log`, `log` is a zsh builtin):

```bash
/usr/bin/log show --last 1h --style compact --predicate 'subsystem == "com.apple.TimeMachine" AND eventMessage CONTAINS "Backup failed"'
```

`BACKUP_FAILED_TARGETVOL_DISK_FULL` means the backup disk needs more than 100 GB free. Check with `diskutil apfs list`, then delete old backups:

```bash
tmutil listbackups
sudo tmutil delete -d /Volumes/2TBSanDsik -t <timestamp>
```

## Resources

<https://talk.macpowerusers.com/t/any-way-to-automate-a-time-machine-backup-mount-backup-unmount/16758/10>
<https://gist.github.com/tjluoma/8c8a05c217daa2de085c9c07531805b3>

<https://akrabat.com/prevent-an-external-drive-from-auto-mounting-on-macos/>
