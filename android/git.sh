#!/data/data/com.termux/files/usr/bin/bash

# 更新Termux中的软件包索引
pkg update

# 升级已安装的软件包
pkg upgrade -y

# 安装Git
pkg install -y git

# 启动 proot-distro 并登录到 Ubuntu
proot-distro login ubuntu << 'EOF'

# 在Ubuntu环境中执行的命令

# 更新软件包索引
apt update

# 升级已安装的软件包
apt upgrade -y

# 安装Git（如果尚未安装）
apt install -y git

# 建立单独的Git用户
adduser gitsync

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

# 复制 authorized_keys 文件
cp /data/data/com.termux/files/home/.ssh/authorized_keys ~/.ssh/

# 设置适当的权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 执行完成后退出gitsync用户的shell会话
exit
EOF_GITSYNC

# 执行完成后退出Ubuntu环境
exit
EOF

# 回到Termux的初始环境