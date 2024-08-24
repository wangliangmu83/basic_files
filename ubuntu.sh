#!/data/data/com.termux/files/usr/bin/bash

folder=ubuntu-fs
tarball="ubuntu.tar.gz"

# Check if the folder already exists
if [ ! -d "$folder" ]; then
	echo "downloading ubuntu-image"
	
	wget "https://raw.githubusercontent.com/wangliangmu83/basic_files/main/ubuntu_23_10_core_cloudimg_amd64_root.tar.gz" -O $tarball
fi

# Check if the tarball exists
if [ ! -f $tarball ]; then
	echo "Error: tarball not found."
	exit 1
fi

cur=$(pwd)

# Ensure we are in the correct directory before extracting
mkdir -p "$folder"
cd "$folder"
echo "decompressing ubuntu image"
tar -xzf "${cur}/${tarball}" --strip-components=1 --no-same-owner --no-same-permissions

# Ensure that the 'root' directory exists
mkdir -p "$cur/$folder/root"

# Ensure that the 'etc' directory exists before creating resolv.conf
mkdir -p "$cur/$folder/etc"
echo "fixing nameserver, otherwise it can't connect to the internet"
echo "nameserver 1.1.1.1" > "$cur/$folder/etc/resolv.conf"
cd "$cur"

# Create the binds directory and script
mkdir -p binds
bin=binds/start-ubuntu.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
CUR_DIR=\$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r ${cur}/$folder"
if [ -n "\$(ls -A binds)" ]; then
	for f in binds/* ;do
		. \$f
	done
fi
command+=" -b /dev"
command+=" -b /proc"
## Uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## Uncomment the following line to mount /sdcard directly to /
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /bin/bash --login"
exec \$command
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "You can now launch Ubuntu with the ./binds/start-ubuntu.sh script"