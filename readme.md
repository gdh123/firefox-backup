This is a bash script to backup firefox profile to a different location, be it a mounted NAS or external HDD

What the script does:
Check if a backup was created today
Check if firefox is currently running
if both is no, the script creates a .7z file with password protection and place it on the specified location
the script will keep the 4 most recent backups others will be deleted
In case the backup could not be generated in the past 30 days it will create a pop up with a warning (probably just working for Ubuntu/popos)
