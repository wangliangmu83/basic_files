#!/data/data/com.termux/files/usr/bin/bash

# 定义设置密码的函数
set_user_password() {
    local user=$1
    # 提示用户设置密码
    while true; do
        echo "请输入新密码 (为用户: $user):"
        read -s -p "" new_password
        echo
        echo "请再次输入密码:"
        read -s -p "" confirm_password
        echo
        
        if [ "$new_password" != "$confirm_password" ]; then
            echo "密码不匹配，请重新输入！"
        else
            # 使用echo命令来传递密码给passwd命令
            echo "$new_password" | proot-distro exec ubuntu -- passwd --stdin $user
            echo "密码设置成功!"
            break
        fi
    done
}

# 更新Termux中的软件包索引
pkg update

# 升级已安装的软件包
pkg upgrade -y

# 安装必要的工具
pkg install -y coreutils  # 确保有coreutils

# 启动 proot-distro 并登录到 Ubuntu
proot-distro login ubuntu << 'EOF_UBUNTU'

# 更新软件包索引
apt update

# 尝试解决依赖问题
apt install -f

# 升级已安装的软件包
apt upgrade -y

# 安装Git
apt install -y git

# 安装Perl及其依赖
apt install -y perl

# 安装SSH客户端
apt install -y openssh-client

# 建立单独的Git用户
adduser gitsync

# 为root用户设置密码
set_user_password root

# 为gitsync用户设置密码
set_user_password gitsync

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

# 确保目标目录存在
mkdir -p ~/.ssh

# 假设Termux用户已经有authorized_keys文件
cp /data/data/com.termux/files/home/.ssh/authorized_keys ~/.ssh/

# 设置适当的权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 执行完成后退出gitsync用户的shell会话
exit
EOF_GITSYNC

# 执行完成后退出Ubuntu环境
exit
EOF_UBUNTU

# 回到Termux的初始环境
echo "Ubuntu中的SSH配置已完成。现在您可以通过密钥认证登录root或gitsync用户。"