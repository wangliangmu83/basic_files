#!/data/data/com.termux/files/usr/bin/bash

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
    pkg install vim openssh proot-distro -y
    pkg install expect
    pkg install openssl-tool
}

generate_ssh_host_keys() {
    log "生成主机密钥..."
    ssh-keygen -A
}

configure_storage_permissions() {
    log "设置Termux的外部存储权限..."
    termux-setup-storage
    if [ $? -ne 0 ]; then
        log "设置存储权限失败！"
        exit 1
    fi
}

setup_ssh_keys() {
    log "设置SSH密钥..."
    SSH_DIR="/data/data/com.termux/files/home/.ssh"
    AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
    PRIVATE_KEY="$SSH_DIR/id_rsa"
    PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

    mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
    touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"

    if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ];then
        ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N ""
        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"
    fi

    if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
        cat "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    fi
}


# 先启动一次sshd服务
log "启动 SSHD 服务..."
/data/data/com.termux/files/usr/bin/sshd -p 8022 -E /data/data/com.termux/files/home/sshd.log &

configure_sshd() {
    log "配置sshd_config..."
    local SSHD_CONFIG_FILE="/data/data/com.termux/files/usr/etc/ssh/sshd_config"
    local config_lines=(
        "PermitRootLogin yes"
        "ListenAddress 0.0.0.0"
        "Port 8022"
        "PubkeyAuthentication yes"
        "AuthorizedKeysFile /data/data/com.termux/files/home/.ssh/authorized_keys"
    )

    for line in "${config_lines[@]}"; do
        if ! grep -q "^${line}$" "$SSHD_CONFIG_FILE"; then
            echo "${line}" >> "$SSHD_CONFIG_FILE"
        fi
    done
}

configure_bashrc() {
    log "开始配置bash.bashrc..."
    local BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
    
    > "$BASHRC_FILE"

    cat <<EOF >> "$BASHRC_FILE"
# 不保存重复的命令
shopt -s histappend
shopt -s histverify
export HISTCONTROL=ignoreboth

# 设置默认命令行提示符
PROMPT_DIRTRIM=2
PS1='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\$\[\e[0m\] '

# 处理不存在的命令
if [ -x /data/data/com.termux/files/usr/libexec/termux/command-not-found ]; then
    command_not_found_handle() {
        /data/data/com.termux/files/usr/libexec/termux/command-not-found "\$1"
    }
fi

# 加载 Bash 自动补全
[ -r /data/data/com.termux/files/usr/share/bash-completion/bash_completion ] && . /data/data/com.termux/files/usr/share/bash-completion/bash_completion

# 启动 SSHD 服务（不输出信息）
log "启动 SSHD 服务..."
/data/data/com.termux/files/usr/bin/sshd -p 8022 -E /data/data/com.termux/files/home/sshd.log &

# 检查 proot-distro 是否已安装
if command -v proot-distro &> /dev/null; then
    if [ -z "\$SSH_CONNECTION" ]; then
        echo "本地登录，直接进入 Ubuntu"
        proot-distro login ubuntu
    else
        if pgrep -f "proot.*-r.*ubuntu" > /dev/null; then
            echo "Termux 已登录到 Ubuntu"
            echo "尝试进入 Ubuntu 发行版"
            proot-distro login ubuntu
        else
            echo "Termux 未登录到 Ubuntu"
            echo "SSH 连接时不登录到 Ubuntu"
        fi
    fi
else
    echo "proot-distro 未安装，跳过相关操作..."
fi

echo "IN_UBUNTU: \${IN_UBUNTU:-未定义}"

trap 'unset IN_UBUNTU; echo "IN_UBUNTU 已清除"' EXIT
EOF

    log "bash.bashrc配置完成"
}

install_ubuntu() {
    log "安装 Ubuntu..."
    proot-distro install ubuntu
}

restart_ssh_service() {
    log "重启 SSH 服务..."
    pkill -HUP sshd
}

# 执行配置任务
configure_storage_permissions
update_upgrade_packages
install_necessary_packages
generate_ssh_host_keys
setup_ssh_keys
set_user_password

# 先启动一次sshd服务
log "启动 SSHD 服务..."
/data/data/com.termux/files/usr/bin/sshd -p 8022 -E /data/data/com.termux/files/home/sshd.log &

configure_sshd
configure_bashrc
install_ubuntu
update_upgrade_packages
restart_ssh_service

# 复制密钥文件到 gitsync 用户
mkdir -p /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/.ssh
cp /data/data/com.termux/files/home/.ssh/authorized_keys /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/.ssh/
if [ $? -eq 0 ]; then
    echo "复制到 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/.ssh/ 成功"
else
    echo "复制到 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/.ssh/ 失败"
fi

# 下载git.sh.enc
curl https://raw.githubusercontent.com/wangliangmu83/basic_files/main/android/git.sh.enc >git.sh.enc

# 输入密码解密文件
openssl aes-256-cbc -d -pbkdf2 -in git.sh.enc -out     

#移动git.sh 
mkdir -p /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/
cp /data/data/com.termux/files/home/git.sh /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/


# 使用 proot-distro exec 在 Ubuntu 中执行命令
proot-distro login ubuntu 

# 授权git.sh
chmod +x /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/gitsync/git.sh

# 执行git.sh
./home/gitsync/git.sh

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"
