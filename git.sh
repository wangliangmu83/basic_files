#!/bin/bash

# 定义日志函数
log() {
    echo "$@"
}

# 设置用户密码的函数
set_user_password() {
    log "设置用户密码..."
    # 使用expect来自动输入密码
    expect << EOF
spawn passwd $1
expect "New password: "
send "$PASSWORD\r"
expect "Retype new password: "
send "$PASSWORD\r"
expect eof
EOF

    if [ $? -eq 0 ]; then
        log "密码设置成功!"
    else
        log "密码设置失败，请重新尝试。"
    fi
}

# 设定一个默认密码
PASSWORD="19831102Wq"

# 安装expect
apt update -y
apt install -y expect

# 首先修改root的密码
set_user_password root

# 升级已安装的软件包
apt update -y
apt upgrade -y
log "升级ubuntu系统软件包"

# 安装Git
apt install -y git

# 安装Perl及其依赖
apt install -y perl

# # 添加gitsync用户
log "添加gitsync用户..."

# 使用-k /nonexistent参数避免复制骨架目录
useradd -m -s /bin/bash -c "Git Sync User" -k /nonexistent gitsync

# 检查/home/gitsync目录是否已存在
if [ ! -d "/home/gitsync" ]; then
    # 如果不存在，则创建目录
    mkdir -p /home/gitsync
fi

# 确保设置目录的所有权和权限
chown gitsync:gitsync /home/gitsync  # 设置所有权为gitsync用户
chmod 755 /home/gitsync  # 设置权限

# 检查用户添加是否成功
if [ $? -eq 0 ]; then
    log "gitsync用户添加成功!"
else
    log "gitsync用户添加失败，请重新尝试。"
fi

# 设置gitsync用户的密码
set_user_password gitsync

# gitsync密钥文件授权
chmod 700 /home/gitsync/.ssh
chmod 600 /home/gitsync/.ssh/authorized_keys
chown -R gitsync:gitsync /home/gitsync/.ssh

#给gitsync限制权限为git-shell
chsh -s /usr/bin/git-shell gitsync

# 切换到gitsync用户
su - gitsync <<-'EOF'
    # 配置全局默认分支名称为 main
    echo "配置全局默认分支名称为 main..."
    git config --global init.defaultBranch main

    # 创建 Git 仓库并初始化
    mkdir -p ~/my_project.git
    cd ~/my_project.git
    echo "初始化 Git 仓库..."
    git init --bare
    echo "git初始化完毕"

    # 配置默认分支名称为 main
    git symbolic-ref refs/heads/master refs/heads/main
    rm -rf .git/refs/heads/master
EOF

# 执行完成后退出gitsync用户的shell会话
log "退出gitsync用户的shell会话..."
exit


# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
