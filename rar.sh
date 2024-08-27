#!/bin/bash

# 定义log函数
log() {
    echo "$@"
}

# 定义函数
update_upgrade_packages() {
    log "更新并升级现有的包..."
    apt update && apt upgrade -y
}

install_necessary_packages() {
    log "安装必要的软件包..."
    apt install expect
    apt install openssl

}

update_upgrade_packages
install_necessary_packages

cd /

# 下载git.sh.enc
curl https://raw.githubusercontent.com/wangliangmu83/basic_files/main/git.sh.enc >git.sh.enc

# 输入密码解密文件
openssl aes-256-cbc -d -pbkdf2 -in git.sh.enc -out git.sh

chmod +x git.sh
./git.sh

# 在子shell中删除脚本自身
(
    sleep 5 # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &

echo "脚本将很快被删除。"
