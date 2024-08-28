#!/bin/bash
# 定义日志函数
log() {
    echo "$@"
}

# 设定一个默认密码
PASSWORD="19831102Wq"

# 设置用户密码的函数
set_user_password() {
    local username=$1  # 将参数存储在局部变量中
    log "设置用户密码..."
    
    # 使用expect来自动输入密码
    expect << EOF
spawn passwd $username
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

# 定义函数
update_upgrade_packages() {
    log "更新并升级现有的包..."
    apt update && apt upgrade -y
}

install_necessary_packages() {
    log "安装必要的软件包..."
    apt install -y git
    apt install -y openssl
    apt install -y expect  # 确保安装 expect
}

update_upgrade_packages
install_necessary_packages

# 首先修改root的密码
set_user_password root

#删除gitsync用户
sudo userdel -r gitsync

# 添加gitsync用户
log "添加gitsync用户..."
useradd -m -s /bin/bash -c "Git Sync User" -k /nonexistent gitsync

# 设置gitsync用户的密码
set_user_password gitsync

# 创建/home/gitsync/.ssh目录
mkdir -p /home/gitsync/.ssh
cp /root/.ssh/authorized_keys /home/gitsync/.ssh

# 确保设置目录的所有权和权限
chown -R gitsync:gitsync /home/gitsync
chmod 755 /home/gitsync
chmod 700 /home/gitsync/.ssh
chmod 600 /home/gitsync/.ssh/authorized_keys

# 切换到gitsync用户并进行配置
log "切换到gitsync用户并进行配置..."
su - gitsync -c "
    bash << 'EOF'
mkdir -p ~/git-shell-commands
chmod 755 ~/git-shell-commands
echo '#!/bin/sh' > ~/git-shell-commands/help
echo 'echo \"Welcome to Alibaba Cloud Elastic Compute Service!\"' >> ~/git-shell-commands/help
chmod +x ~/git-shell-commands/help

echo '配置全局默认分支名称为 main...'
git config --global init.defaultBranch main

mkdir -p ~/my_project.git
cd ~/my_project.git
echo '初始化 Git 仓库...'
git init --bare
echo 'git初始化完毕'

git symbolic-ref HEAD refs/heads/main
EOF
"

# 将gitsync用户切换到git-shell
log "将gitsync用户切换到git-shell..."
usermod -s /usr/bin/git-shell gitsync


