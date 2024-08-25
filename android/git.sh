#!/data/data/com.termux/files/usr/bin/bash

# 更新Termux中的软件包索引
pkg update

# 升级已安装的软件包
pkg upgrade -y

# 启动 proot-distro 并登录到 Ubuntu
proot-distro login ubuntu << 'EOF_UBUNTU'

# 更新软件包索引
apt update

# 如果更新失败，则尝试重试
while ! apt update; do
    echo "APT 更新失败，尝试重试..."
done

# 安装必要的工具
apt install -y expect

# 设置root用户密码
set_root_password() {
    log "设置root用户密码..."
    while true; do
        echo "请输入新密码:"
        read -s -p "" new_password
        echo
        echo "请再次输入密码:"
        read -s -p "" confirm_password
        echo
        
        if [ "$new_password" != "$confirm_password" ]; then
            echo "密码不匹配，请重新输入！"
            continue
        fi

        # 使用expect来处理交互式输入
        expect -c "
            set timeout 30
            spawn passwd root
            expect \"New password:\"
            send \"$new_password\r\"
            expect \"Retype new password:\"
            send \"$new_password\r\"
            expect eof
        "
        if [ $? -eq 0 ]; then
            log "密码设置成功!"
            break
        else
            log "密码设置失败，请重新尝试。"
        fi
    done
}

# 设置root用户密码
set_root_password

# 安装SSH服务器
apt install -y openssh-server

# 配置sshd
configure_sshd() {
    log "配置sshd_config..."
    local SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
    local config_lines=(
        "PermitRootLogin yes"
        "ListenAddress 0.0.0.0"
        "Port 8022"
        "PubkeyAuthentication yes"
        "AuthorizedKeysFile      .ssh/authorized_keys"
    )

    for line in "${config_lines[@]}"; do
        if ! grep -q "^${line}$" "$SSHD_CONFIG_FILE"; then
            echo "${line}" >> "$SSHD_CONFIG_FILE"
        fi
    done

    # 设置适当的权限
    chmod 600 "$SSHD_CONFIG_FILE"
}

# 配置SSH服务
configure_sshd

# 启动SSH服务
systemctl enable ssh
systemctl start ssh

# 执行完成后退出Ubuntu环境
exit
EOF_UBUNTU

# 回到Termux的初始环境
echo "Ubuntu中的SSH配置已完成。现在您可以通过密钥认证登录root用户。"