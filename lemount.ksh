#!/usr/bin/env ksh93
# lemount - Luiz' extensions for mount
# This is a prototype made with Korn Shell, probabily I will rewrite this in Go.

# Source configuration file
source /etc/leconf

# For some reason, trap isn't catching function errors...
# So, at least on my version of Korn Shell, this isn't working for now.
trap '{ errare "Error at function $0"; }' ERR SIGINT

base_number='0'
program_name="$0" # We need to get it outside a function, so that $0 won't have
		  # the function identifier as its content.

function main {
	if [ -z "$@" ]; then
		interactive_prompt
	else
		noninteractive $@
	fi
	exit 0
}

function interactive_prompt {
	create_mounting_points
	# List disks with fdisk
	printmsg 'Available disks:'
	fdisk -l 1>&2
	printmsg 'Which disk do you want to mount? '
	read disk_name
	disk=$(realpath $disk_name); unset disk_name
	check_virtual_disk "$disk"
	
	PS3='What is it? '
	select type in ${mount_points[@]}; do
		type=$type
		break
	done	
	printmsg 'Disk %s is %s%s\n' "$disk" "$type" "$disk_postfix" 1>&2
	
	count_lemounted_disks	
	
	mount_block "${disk}" "${root}${type}/${base_number}${disk_postfix}" \
	&& link_from_type2mnt

	success
}

function noninteractive {
	# getopts
	while getopts ":D:t:" options; do
		case "$options" in
			D) export disk_name="$OPTARG" ;;
			t) export type="$OPTARG" ;;
			\?|h) print_help "$OPTARG" ;;
		esac
	done
	shift $(( OPTIND -1 ))

	create_mounting_points
	
	disk=$(realpath $disk_name); unset disk_name
	check_virtual_disk "$disk"
	printmsg 'Disk %s is %s%s\n' "$disk" "$type" "$disk_postfix"
	
	count_lemounted_disks	
	
	mount_block "${disk}" "${root}${type}/${base_number}${disk_postfix}" \
		&& link_from_type2mnt \
		&& success
}

function create_mounting_points {
	printmsg 'Creating mount points...\n' 1>&2 &
	for (( i=0; i<${#mount_points[@]}; i++ )); do
		test ! -e "${root}${mount_points[${i}]}" \
		&& mkdir -p "${root}${mount_points[${i}]}" 1>&2
	done
	printmsg  '%s\n\n' 'done.'

}

function check_virtual_disk {
	# There's possible a better way of doing this, but for now this works
	# and I won't be changing.

	# Takes $disk as argument
	# By block name
	if echo "${1##*/}" | grep '^loop' 2>&1 > /dev/null; then
		export disk_postfix='v'
	# By file extension (only *.{img,IMG} for now)
	elif echo "$1" | grep -i 'img' 2>&1 > /dev/null; then
		export disk_postfix='v'
		export isloop='y'
	else
		export disk_postfix=''
	fi
}

function count_lemounted_disks {
	# This function counts directories already created and creates a new
	# directory for the new mounted disk

	# Check if the variables are being actually exported
	printdbg \
		'%s() debugging:\nroot=%s\ntype=%s\nbase_number=%s\ndisk_postfix="%s"\n' \
	       		"$0" "$root" "$type" "$base_number" "$disk_postfix" 1>&2

		  # ls -A the disk directory, if it doesn't exist yet, the
		  # errors will be supressed by redirecting the stderr to
		  # /dev/null.
	if [ ! -z $(ls -A "${root}${type}/${base_number}${disk_postfix}" \
		2>/dev/null) ]; then
		for ((;;)); do
			# If a disk with the base_number is already
			# mounted/existent, then try one more
			if [ -e "${root}${type}/${base_number}${disk_postfix}" ]; then
				base_number=$(( base_number + 1 ))
			else
				break
			fi
		done
	fi

	# If the disk mounting target don't exist, create it
	test ! -e "${root}${type}/${base_number}${disk_postfix}" \
		&& mkdir -p "${root}${type}/${base_number}${disk_postfix}" 1>&2

	return 0
}


function mount_block {
# Kinda "gambiarrado", but since export -f isn't avaible and typeset -xf wasn't
# working either, I decided to do this.
	printdbg '%s() debugging:\ndisk=%s\ntarget=%s\n' "$0" "$1" "$2" 1>&2
	if [ isloop == 'y' ]; then
		# This may will break compatibility with other UNIXes, but who
		# cares? This is used officially only on Copacabana.
		# Also, for disks which have multiple partitions, it would be
		# cool to re-display them offering to mount again if needed.
		mount -o loop "$1" "$2"; ec=$?
	else
		mount "$1" "$2"; ec=$?
	fi

	return $ec
}

function link_from_type2mnt {
	# Check if the variables are being actually exported
	printdbg \
		'%s() debugging:\nroot=%s\ntype=%s\nbase_number=%s\ndisk_postfix="%s"\n' \
	       		"$0" "$root" "$type" "$base_number" "$disk_postfix" 1>&2

	# If there's no link from the disk original target to /mnt, do it
	if [ -z $(ls -A "${mnt}/${type}${base_number}${disk_postfix}" \
	       	2>/dev/null) ]; then
			{ 
			        test -d "${mnt}/${type}${base_number}${disk_postfix}" \
		       	        || mkdir "${mnt}/${type}${base_number}${disk_postfix}" 
			} \
		       	&& mount -o bind "${root}${type}/${base_number}${disk_postfix}" \
		       	        "${mnt}/${type}${base_number}${disk_postfix}"
	fi
}

function success {
	printmsg '%s was mounted succesfully at %s.\n' "${disk}" \
		"${root}${type}/${base_number}${disk_postfix}"
	echo "ledisk=${root}${type}/${base_number}${disk_postfix}"
	
	return 0
}

function realpath {
  # From https://git.io/mitzune
  
  # ./sources.txt -> sources.txt
  file_basename="$(basename "$1")"
  # ./sources.txt -> .
  file_dirname="$(dirname "$1")"
	# get the absolute directory name
	# example: ./sources.txt -> /usr/src/copacabana-repo/sources.txt
	# cd ./; pwd -> /usr/src/copacabana-repo
  echo "$(cd "${file_dirname}"; pwd)/${file_basename}"
}

# Errare humanum est.
function errare {
	rc="$?"
	printf 'Exit code: %s\n' "$rc"
	# Delete the directory only if it in fact exists, to avoid the
	# "rmdir: //0: No such file or directory" error.
	[ -z "${root}${type}/${base_number}${disk_postfix}" ] \
	       && rmdir "${root}${type}/${base_number}${disk_postfix}"
	exit "$rc"
}

# printf(1), but for stderr per default.
# This helps us a lot when eval'ng $ledisk on a script.
function printmsg {
	printf "$@" 1>&2;
}

function printdbg {
  # Prints only if debugging is enabled.
  if $(echo "$debugging" | grep -i '^y'); then
	  printf "$@"
  else
	  return 0 # Do nothing, literally.
  fi
}

function print_help {
	printmsg '%s: illegal option "%s"\n[usage]: %s -D /dev/disk1 -t %s\n' \
		$program_name $1 $program_name "$(echo ${mount_points[*]} | tr ' ' '|')"
}

main $@
