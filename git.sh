#!/bin/bash

# 定义日志函数
log() {
    echo "$@"
}
# 设定一个默认密码
PASSWORD="19831102Wq"

apt update && apt upgrade -y         
apt install -y expect
    
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

# 首先修改root的密码
set_user_password root

# 定义函数
update_upgrade_packages() {
    log "更新并升级现有的包..."
    apt update && apt upgrade -y
}

install_necessary_packages() {
    log "安装必要的软件包..."
    apt install -y git
    apt install -y openssl

}

update_upgrade_packages
install_necessary_packages


# # 添加gitsync用户
log "添加gitsync用户..."

# 创建新用户gitsync，指定必要的用户配置
useradd -m -s /usr/bin/git-shell -c "Git Sync User" -k /nonexistent gitsync
# -m: 创建用户家目录
# -s /bin/bash: 设置用户的shell为bash
# -c "Git Sync User": 设置用户的描述信息
# -k /nonexistent: 设置用户的默认系统配置文件，如果指定文件不存在则不使用

# 检查/home/gitsync目录是否已存在
if [ ! -d "/home/gitsync" ]; then
    # 如果不存在，则创建目录
    mkdir -p /home/gitsync
    mkdir -p /home/gitsync/.ssh
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

cp /root/.ssh/authorized_keys /home/gitsync/.ssh
chmod 600 /home/gitsync/.ssh/authorized_keys
chown -R gitsync:gitsync /home/gitsync/.ssh
chown -R gitsync:gitsync /home/gitsync/.ssh/authorized_keys


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

    # 创建 main 分支
    git symbolic-ref HEAD refs/heads/main
EOF

# 执行完成后退出gitsync用户的shell会话
log "退出gitsync用户的shell会话..."
exit

#给gitsync限制权限为git-shell
chsh -s /usr/bin/git-shell gitsync
 

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
