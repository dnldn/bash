#SMB Copy and paste from current directory to sambashare.
Script to make copying and pasting to and from samba shares using smbclient a little less painful. The directory in which the command is executed is copied to or from.

To install:
Download bash.sh and bash.conf to your /usr/local/bin.sh

Edit /etc/bash.bashrc - add following line:
alias smb="bash /usr/local/bin/smb.sh"

Restart console or source ~/.bashrc to initialize.

Usage:

Manual:
smb --help

Change MAC address being referenced from list populated by ARP for smbclient:
smb -m

Change share being referenced on selected MAC address:
(For information on setting up samba to share files between Windows servers and Linux, refer to this excellent tutorial. https://www.youtube.com/watch?v=oRHSrnQueak)
smb -s 

To copy all files and subfolders from current directory to currently-selected SMB share while preserving the linux path (useful for destructive backups):
smb -cp

To copy all files and subfolders from current directory to currently-selected SMB share, using the name of the folder instead of its absolute path:
smb -cl

To do the above but create a newly-named folder (non-destructive):
smb -cn foldername

To copy all files from SMB share to current folder on linux:
smb -pp

To copy files from specified folder on SMB server to current folder on linux:
smb -pn
