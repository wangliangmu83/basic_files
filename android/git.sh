#!/data/data/com.termux/files/usr/bin/bash

# 更新Termux中的软件包索引
pkg update

# 升级已安装的软件包
pkg upgrade -y

# 启动 proot-distro 并登录到 Ubuntu
proot-distro login ubuntu << 'EOF_UBUNTU'

# 更新软件包索引
apt update

# 安装expect
apt install -y expect

# 首先修改root的密码
passwd

# 尝试解决依赖问题
apt install -f

# 安装Git
apt install -y git

# 安装Perl及其依赖
apt install -y perl

# 安装SSH服务器
apt install -y openssh-server

# 升级已安装的软件包
apt upgrade -y

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

# 建立单独的Git用户
adduser gitsync

# 为gitsync用户设置密码
passwd

# 复制密钥文件到root用户
mkdir -p /root/.ssh
cp /data/data/com.termux/files/home/.ssh/authorized_keys /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# 复制密钥文件到gitsync用户
mkdir -p /home/gitsync/.ssh
cp /data/data/com.termux/files/home/.ssh/authorized_keys /home/gitsync/.ssh/
chown -R gitsync:gitsync /home/gitsync/.ssh
chmod 700 /home/gitsync/.ssh
chmod 600 /home/gitsync/.ssh/authorized_keys

# 切换到gitsync用户
su - gitsync << 'EOF_GITSYNC'

# 创建 Git 仓库并初始化
mkdir -p ~/my_project.git
cd ~/my_project.git
git init --bare
git config --global init.defaultBranch main

# 添加一些测试提交
echo "Initial commit" > README.md
git add .
git commit -m "Initial commit"

# 执行完成后退出gitsync用户的shell会话
exit
EOF_GITSYNC

# 执行完成后退出Ubuntu环境
exit
EOF_UBUNTU

# 回到Termux的初始环境
echo "Ubuntu中的SSH配置已完成。现在您可以通过密钥认证登录root或gitsync用户。"