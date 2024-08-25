#!/data/data/com.termux/files/usr/bin/bash

# 定义设置密码的函数
set_user_password() {
    # 提示用户设置密码
    while true; do
        echo "请输入新密码:"
        read -s -p "" new_password
        echo
        echo "请再次输入密码:"
        read -s -p "" confirm_password
        echo
        
        if [ "$new_password" != "$confirm_password" ]; then
            echo "密码不匹配，请重新输入！"
        elif ! sudo passwd gitsync <<< "$new_password"; then
            echo "密码设置失败，请重新尝试。"
        else
            echo "密码设置成功!"
            break
        fi
    done
}

# 更改Termux的软件包源为清华大学镜像
echo "更改Termux的软件包源为清华大学镜像..."
cat > $PREFIX/etc/apt/sources.list << EOF
deb http://mirrors.tuna.tsinghua.edu.cn/termux stable main
EOF

# 更新Termux中的软件包索引
pkg update

# 升级已安装的软件包
pkg upgrade -y

# 安装Git
pkg install -y git

# 启动 proot-distro 并登录到 Ubuntu
proot-distro login ubuntu << 'EOF'

# 更改Ubuntu的软件包源为清华大学镜像
echo "更改Ubuntu的软件包源为清华大学镜像..."
cat > /etc/apt/sources.list << EOF
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse

# 以下为可选的更新源
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse

deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
EOF

# 更新软件包索引
apt update

# 升级已安装的软件包
apt upgrade -y

# 自动响应 adduser 命令的提示
echo -e "gitsync\n\n\n\n\n\n\n\n" | adduser gitsync

# 调用设置密码的函数
set_user_password

# 安装必要的工具包
apt install -y dialog

# 尝试安装 debconf-utils 和 libterm-readline-perl
# 如果找不到软件包，尝试从其他源安装
if ! apt install -y debconf-utils; then
    echo "尝试从其他源安装 debconf-utils..."
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
    apt install -y debconf-utils
fi

if ! apt install -y libterm-readline-perl; then
    echo "尝试从其他源安装 libterm-readline-perl..."
    apt install -y perl-modules-5.30
fi

# 安装Git（如果尚未安装）
apt install -y git

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