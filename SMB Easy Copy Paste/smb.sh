#!/bin/bash

#Source MAC address and sharename from configuration file.
. /usr/local/bin/smb.conf

#Colors for output on help prompt.
LIGHTRED='\033[0;91m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#Getting IPV4 address from sourced MAC address. This is faster than arp -a because DNS doesn't need to resolve, and DHCP can shift static address.
GetIpFromMacAddress() {
	arp -n | grep $MAC | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"
}

#Get last folder name from path in which program is currently being executed.
GetPenultimateFolderName() {
	local path=$(pwd)
	basename $path
}


# Generate menu from input array.
MenuFromArray()
{
	select item; do
	# Check the selected menu item number
	if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ];
	then
		echo "The selected SMB target is $item"
			
			# Capture current item and preserve old item.
			new_mac=$item
			old_mac=$MAC

			# Escape every character in string sequence.
			new_mac=sed -e 's/./\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/'

			# Extract MAC address from new sequence and change .conf file.
			new_mac=$(echo -e $new_mac | grep -o -E "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}")
			sudo sed -i "s/MAC=.*/MAC=$new_mac/" /usr/local/bin/smb.conf
			echo "MAC changed from $old_mac to $new_mac."

		break;
	elif [ 0 -eq "$REPLY" ]
	then
		break;
	else
		echo "Select any number from 1-$#, or type 0 to make no changes."
	fi
	done
}


#Help display.
DisplayHelp() {
	echo -e "\n${LIGHTRED}Configuring default targets.${NC}"
	echo -e "${RED}-l${NC}: List all available shares from current IP address and list all mac addresses on network."
	echo -e "${RED}-s${NC}: Change the share file being referenced from smb.conf (requires superuser access)."
	echo -e "${RED}-m${NC}: Change MAC address being referenced from smb.conf (requires superuser access)."
	echo -e "${RED}-o${NC}: Open smb with current ip address. This is done by default if no argument is passed."

	echo -e "\n${LIGHTRED}Copying from current directory to SMB shared folder:${NC}"
	echo -e "${RED}-cp${NC}: Create new folder on SMB server- preserving linux path, and copy all files from current directory to that path."
	echo -e "${RED}-cl${NC}: Create new folder on SMB server- only using penultimate folder name, and copy all files from current directory to that path."
	echo -e "${RED}-cn${NC}: Create new named folder from argument on SMB server- same as -n unless an argument is passed."

	echo -e "\n${LIGHTRED}Copy files from SMB server folder to current directory.${NC}"
	echo -e "${RED}-pp${NC}: Copy all files from SMB server to current folder."
	echo -e "${RED}-pn${NC}: Copy specific folder from SMB server to new folder. Second argument if passed will rename folder."
}

ip=$(GetIpFromMacAddress)
path=$(pwd)
folder=$(GetPenultimateFolderName)

case $1 in

	-h|--help|-help|/?)
		DisplayHelp
		;;
	-l)
		#List available shares from current IP address.
		echo -e "${RED}Valid shares on currently-selected ip address ($ip):${NC}"
			smbclient --list=//$ip/ --no-pass | grep Disk
			echo -e "\n${RED}Valid mac addresses on network:${NC}"
			arp -n | grep -o -E "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}"
		;;
	-s)
		#Change smb.conf to update targeted share file.
		if [ $# -gt 1 ]
		then
			new_share="${@:2}"
			old_share=$SHARE
			sudo sed -i "s/SHARE=.*/SHARE=$new_share/" /usr/local/bin/smb.conf
			echo "Share changed from \"$old_share\" to \"$new_share\"."

		else
			smbclient //$ip/$SHARE -N
		fi
		;;
	-m)
		#Change smb.conf to update targeted mac address- checking to see if mac address is valid selection from network.
		declare -a a
		while read i; do
			a=( "${a[@]}" "$i" )
			if [[ $i == *"$MAC"* ]];
			then
				echo -e "${CYAN}$i ${NC}is the currently-selected IP address."
			fi
		done < <(arp -a)
		echo -e "Select an address from below to set as the target for smbclient. ${LIGHTRED}(0 to make no changes)\n${NC}"
		MenuFromArray "${a[@]}"
		;;

	-o)
		#Open smb with ip address.
		smbclient //$ip/$SHARE -N
		;;
	-cp)
		#Create new folder, preserving linux path, and copy all files from current directory to that path.
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;mkdir '$path';cd '$path';mput *'
		;;
	-cl)
		#Create new folder, only using penultimate folder name, and copy all files from current directory to that path.
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;mkdir '$folder';cd '$folder';mput *'
		;;
	-cn)
		#Create new folder from argument; same as -n unless a second argument is passed.
		if [ $# -eq 2 ]
		then
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;mkdir '$2';cd '$2';mput *'
		else
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;mkdir '$folder';cd '$folder';mput *'
		fi
		;;
	-pp)
		#Copy all files from SMB server to current folder.
		smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;;mget *'
		;;
	-pn)
		#Copy specific folder from SMB server to new folder. Second argument if passed will rename folder.
		#TODO: implement error catching - check for existence of directory on smb side before executing and display error. 
		if [ $# -eq 3 ]
		then
			mkdir $3
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;cd '$2';lcd '$path'/'$3';mget *'
		elif [ $# -eq 2 ]
		then
			mkdir $2
			smbclient //$ip/$SHARE -N -c 'mask "";recurse ON;prompt OFF;cd '$2';lcd '$path'/'$2';mget *'
		else
			echo "No argument passed!"
			smbclient //$ip/$SHARE -N
		fi
		;;
	*)
		#Open SMB if no argument is passed.
		smbclient //$ip/$SHARE -N
		;;
esac
