#!/data/data/com.termux/files/usr/bin/bash

folder=ubuntu-fs
tarball="ubuntu.tar.gz"

# Check if the folder already exists
if [ ! -d "$folder" ]; then
    echo "downloading ubuntu-image"
    case `dpkg --print-architecture` in
        aarch64) archurl="arm64" ;;
        arm)     archurl="armhf" ;;
        amd64)   archurl="amd64" ;;
        i*86)    archurl="i386" ;;
        x86_64)  archurl="amd64" ;;
        *)       echo "unknown architecture"; exit 1 ;;
    esac
    wget "https://raw.githubusercontent.com/wangliangmu83/basic_files/main/ubuntu-23-10-core-cloudimg-amd64-root.tar.gz" -O $tarball
fi

# Check if the tarball exists
if [ ! -f $tarball ]; then
    echo "Error: tarball not found."
    exit 1
fi

cur=`pwd`
mkdir -p "$folder"
cd "$folder"
echo "decompressing ubuntu image"
tar -xzf ${cur}/${tarball} --strip-components=1 --no-same-owner --no-same-permissions

# Ensure that the 'etc' directory exists before creating resolv.conf
mkdir -p etc
echo "fixing nameserver, otherwise it can't connect to the internet"
echo "nameserver 1.1.1.1" > etc/resolv.conf
cd "$cur"

mkdir -p binds
bin=start-ubuntu.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A binds)" ]; then
    for f in binds/* ;do
        . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to /
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ]; then
    # Start an init process for a more traditional login experience
    exec \$command -- /bin/bash -c 'apt update && apt install -y vim; exec /sbin/init'
else
    \$command -c "\$com"
fi
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "You can now launch Ubuntu with the ./${bin} script"