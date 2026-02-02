#!/bin/bash
#
# Backup directory trees with 'rsync'.
#
# AS190323
#

#
# backup functions
#
VERSION="1.04 (01-02-2026)"

#
# diskbackup [test] SRCDIR DSTDIR
#
diskbackup () {
	# mountpoints for USB drives for even and odd months
	USBMOUNT_EVEN=/mnt/st5
	USBMOUNT_ODD=/mnt/fcmob-xxs
	
	# determine which drive to use (based on month)
	if [ "$1" == "test" ]; then
		mntpoint=~/tmp/backuptest
		echo "using test target directory for backup"
		shift
	else if [ $[ 10#$(date +"%m") % 2 ] -eq "0" ]; then 
		echo "even month, use Samsung T5 for backup"
		mntpoint=$USBMOUNT_EVEN
	else
		echo "odd  month, use Freecom mobile XXS for backup"
		mntpoint=$USBMOUNT_ODD
		fi
	fi
	# check if target exists and is writable
	test -w $mntpoint/$BACKUPPATH ||
		{ echo "expected backup target doesn't exist: \"$mntpoint/$BACKUPPATH\""; exit 1; }
		
	SRCDIR=$1
	DSTDIR=$2

	#
	# print info and let user confirm to start backup
	#
	echo "backing up from $SRCDIR to $mntpoint/$BACKUPPATH/$DSTDIR"

	if [ -w $mntpoint/$BACKUPPATH/$DSTDIR ]; then
		echo "existing backup directory will be used: \"$DSTDIR\""
	else
		echo "backup directory will be created: \"$DSTDIR\""
	fi
	 
	if [ ! $BATCHMODE ]; then
		read -p "continue? (y/[n])"
		[ "$REPLY" != 'y' ] && exit 1; echo
	fi

    # user backup
    set -x
    rsync $RSYNCOPTS $SRCDIR/ $mntpoint/$BACKUPPATH/$DSTDIR
 }

#
# phonebackup DSTDIR
#
phonebackup () {
	# mountpoints for USB drives for even and odd months
	USBMOUNT_EVEN=/mnt/st5
	USBMOUNT_ODD=/mnt/fcmob-xxs
	
	# determine which drive to use (based on month)
	if [ "$1" == "test" ]; then
		mntpoint=~/tmp/backuptest
		echo "using test target directory for backup"
		shift
	else if [ $[ 10#$(date +"%m") % 2 ] -eq "0" ]; then 
		echo "even month, use Samsung T5 for backup"
		mntpoint=$USBMOUNT_EVEN
	else
		echo "odd  month, use Freecom mobile XXS for backup"
		mntpoint=$USBMOUNT_ODD
		fi
	fi
	# check if target exists and is writable
	test -w $mntpoint/$BACKUPPATH ||
		{ echo "expected backup target doesn't exist: \"$mntpoint/$BACKUPPATH\""; exit 1; }
		
	DSTDIR=$1
		
	#
	# print info and let user confirm to start backup
	#
	echo "backing up from phone to $mntpoint/$BACKUPPATH/$DSTDIR"

	if [ -w $mntpoint/$BACKUPPATH/$DSTDIR ]; then
		echo "existing backup directory will be used: \"$DSTDIR\""
	else
		echo "backup directory will be created: \"$DSTDIR\""
	fi
	 
	if [ ! $BATCHMODE ]; then
		read -p "continue? (y/[n])"
		[ "$REPLY" != 'y' ] && exit 1; echo
	fi

	ANDROIDOPTS="--omit-dir-times --no-perms"
	#ANDROIDOPTS="--no-perms"

	# MTP mountpoint for 'Andis S21 FE 5G'
	MTPMOUNT=/run/user/$UID/gvfs/mtp\:host\=SAMSUNG_SAMSUNG_Android_RZCW510ZT0N
	ANDROID_USERDATA="Interner Speicher"
	PHONE_USER_PATH=$MTPMOUNT/"$ANDROID_USERDATA"

   set -x
   RSYNCOPTS="$RSYNCOPTS --exclude=*.tile --exclude=OruxMapsCacheImages.db"
    
    rsync $RSYNCOPTS $ANDROIDOPTS "$PHONE_USER_PATH"/Andi $mntpoint/$BACKUPPATH/$DSTDIR
    
    rsync $RSYNCOPTS $ANDROIDOPTS "$PHONE_USER_PATH"/noteeverything/text $mntpoint/$BACKUPPATH/$DSTDIR

    rsync $RSYNCOPTS $ANDROIDOPTS                       \
        "$PHONE_USER_PATH"/oruxmaps/preferences    \
        "$PHONE_USER_PATH"/oruxmaps/dem                 \
        "$PHONE_USER_PATH"/oruxmaps/mapstyles       \
        "$PHONE_USER_PATH"/oruxmaps/mapfiles          \
        "$PHONE_USER_PATH"/oruxmaps/tracklogs         \
    $mntpoint/$BACKUPPATH/$DSTDIR/oruxmaps
	
	rsync $RSYNCOPTS $ANDROIDOPTS "$PHONE_USER_PATH"/Android/media/btools.routingapp/brouter/segments4 \
	$mntpoint/$BACKUPPATH/$DSTDIR

}

rhostbackup () {
    # backup to/from remote host
	SRCDIR=$1
	DSTDIR=$2

  # in case of Firefox exclude 'storage'
	RSYNCOPTS="$RSYNCOPTS --exclude=firefox/*/storage/"

	# in case of Chrome exclude CacheStorage
	RSYNCOPTS="$RSYNCOPTS --exclude=Service*Worker/CacheStorage/"

	if ! ping -w5 -c2 saentis > /dev/null 2>&1; then
		echo "host not reachable, terminating"
	else
		set -x
		rsync $RSYNCOPTS "$SRCDIR/" "$DSTDIR"
	fi
}


#
# set rsync options:
#   -n                dry-run
#   -a                archive
#   -i                 output a change-summary for all updates
#   -m               prune empty directories
#   --del            delete extraneous files from dest dirs
#   --stats -h    statistics (human readable)
# 
RSYNCOPTS="--exclude cache2/entries -aim --del --stats -h"

# backup path on target device
BACKUPPATH="Backup"

# print usage info
if [ $# == 0 ]; then
    echo "Usage: `basename $0` [-b] [-n] [-d | -p | -r] [test] SRCDIR DSTDIR"
	echo "	-v: print version info and exit"
	echo "	-b: run in batch mode (used by cron)"
	echo "	-n: do a dry run (nothing will be changed)"
	echo "	-p: do a phone backup"
	echo
	echo
	echo "command line examples:"
	echo "	backup to disk:"
	echo "		backup -d Andi user/Ai-2023"
	echo "		backup -n -d kathi@saentis:/home/kathi/Kathi user/Ki-2023"
	echo "	backup Firefox/Chrome profiles to disk:"
	echo "		backup -d /home/ans/snap/firefox/common/.mozilla/firefox Firefox/Ai"
	echo "		backup -d kathi@saentis:/home/kathi/snap/firefox/common/.mozilla/firefox Firefox/Ki"
	echo "		backup  -d /home/ans/.config/google-chrome/Default Chrome/Ai"
	echo
	echo "	backup phone (to disk):"
	echo "		backup -p S21FE-2025"
	echo
	echo "	backup from/to remote host:"
	echo "		backup -r kathi@saentis:/home/kathi/Kathi /home/kathi/Kathi"
	echo "		backup -r /home/ans/Andi ans@saentis:/home/ansAndi"
	echo "		backup -r /home/ans/Andi ans@saentis:/home/ansAndi"
	echo "		backup -r /home/ans/snap/firefox/common/.mozilla ans@saentis:/home/ans/snap/firefox/common/.mozilla"
	exit
fi

# print version info
if [ "$1" == "-v" ]; then
    echo backup version $VERSION
	exit
fi

echo
echo "-------------------------------------------------------------------------------"
echo "backup started: `date`"

# batch mode?
if [ "$1" == "-b" ]; then
    BATCHMODE="1"
    shift
fi

# do a dry-run?
if [ "$1" == "-n" ]; then
    RSYNCOPTS="-n $RSYNCOPTS"
    shift
fi

case "$1" in
	-d)
		diskbackup $2 $3 $4
		;;

	-p)
		phonebackup $2 $3
		;;

	-r)
		rhostbackup "$2" "$3"
		;;

	*)
		echo "unsupported option: $1"
esac
