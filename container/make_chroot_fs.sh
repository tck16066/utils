#/bin/bash

#
# Copyright 2017, Trevor C Kemp.
#

MB_TO_B=1000000

function print_help() {
  echo "make_chroot_fs.sh - Work under a sandbox on your own system, using your own system."
  echo ""
  echo "  -p|--persistent-dir    The comma-sep dirs that you can write to that will have your"
  echo "                         changes persist on the real filesystem."
  echo "  -o|--overlaid-fs       The place where changes to the FS are stored. Changes are"
  echo "                         recorded here rather than the real FS."
  echo "  -b|--base-fs           The filesystem on the system that you want to use as your"
  echo "                         work environment. For most people, this will be /."
  echo "  -c|--create-size       When you first run, you need to create the overlad-fs. This"
  echo "                         will create a file of the specified size and format it with"
  echo "                         ext4 to use as a filesystem."
  exit -1
}


for i in "$@"
do
case $i in
    -h|--help)
    print_help
    ;;
    -p=*|--persistent-dir=*)
    # HOME_DIR is the persistent directory that the user wants to mount that
    # always looks the same under the chroot and the REAL fs. Any changes made
    # here are also made on the REAL, LIVE FS.
    HOME_DIR="${i#*=}"
    shift # past argument=value
    ;;
    -o=*|--overlaid-fs=*)
    # This is where "temporary" changes are stored.
    OVERLAID_FS="${i#*=}"
    shift # past argument=value
    ;;
    -b=*|--base-fs=*)
    # This is the underlying system you want to have mirrored in your chroot.
    BASE_FS="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--create-size=*)
    # You need to create an overlay FS to mirror into the first time you launch this
    # script. Do that by setting this variable. Recommend at least 1024. DO NOT USE THIS
    # OPTION IF YOU DO NOT WANT TO FORMAT THE OVERLAID_FS FILE!!!
    CREATE_OVERLAY_SIZE="${i#*=}"
    shift # past argument with no value
    ;;
    *)
    HUH="${i#*=}"
    echo "I don't know $HUH"
    print_help
    ;;
esac
done


if [ -z "$BASE_FS" ]; then
  echo "I don't know which dir to overlay on top of. -b/--base-fs"
  print_help
fi


if [ -z  "$OVERLAID_FS" ]; then 
  echo "I need to know where to store overlay changes. -o/--overlaid-fs"
  print_help
else
  if [ -n "$CREATE_OVERLAY_SIZE" ]; then
    CREATE_OVERLAY_SIZE_B=$((CREATE_OVERLAY_SIZE *  MB_TO_B))
    echo "Creating $CREATE_OVERLAY_SIZE MB file, $OVERLAID_FS"
    # Create space for writeable OS.
    dd if=/dev/zero of=$OVERLAID_FS bs=4096 count=$(( $CREATE_OVERLAY_SIZE_B / 4096  ))
    mkfs -t ext4 $OVERLAID_FS
  fi

  if [ ! -f "$OVERLAID_FS" ]; then
    echo "$OVERLAID_FS does not exist as a simple file, you putz."
    print_help
  fi
fi 

if [[  -n "$CREATE_OVERLAY_SIZE" && -z "$OVERLAID_FS"  ]]; then
  echo "If you specify a creation size, you need to specify an overlay fs file. -c/--create-size and -o/--overlaid-fs"
  print_help
fi


rm -f lower

mkdir -p upper merged

ln -s $BASE_FS lower

# Mount two filesystems
mount $OVERLAID_FS upper
mkdir -p upper/work
mkdir -p upper/upper

mount -t overlay overlay -o lowerdir=lower,upperdir=upper/upper,workdir=upper/work merged

cd merged

function mount_it()
{
    mkdir -p ./$1
    mount -o bind $1 ./$1
}

OTHER_MOUNTS=(/run /dev /dev/pts /proc /sys)

for v in "${OTHER_MOUNTS[@]}"; do
    mount_it $(realpath $v)
done

IFS=","
for v in $HOME_DIR; do
  mount_it $(realpath $v)
done

# do chroot
cd ..
chroot merged


# Tear Down
IFS=","
for v in $HOME_DIR; do
  umount merged$(realpath $v)
done


for ((v=${#OTHER_MOUNTS[@]}-1; v>=0; v--)); do
    umount merged/$(realpath ${OTHER_MOUNTS[$v]})
done

umount merged
umount upper
