#!/bin/bash

# 创建新用户并提示输入密码
sudo adduser website

# 将新用户添加到 sudo 组
sudo usermod -aG sudo website

# 设置 SSH 目录和权限，并复制公钥
sudo mkdir -p /home/website/.ssh
sudo chmod 700 /home/website/.ssh
sudo cp /root/.ssh/authorized_keys /home/website/.ssh/
sudo chown -R website:website /home/website/.ssh
sudo chmod 600 /home/website/.ssh/authorized_keys

# 切换到新用户并安装 Hugo
sudo su - website << 'EOF'
sudo apt-get update
sudo apt-get install -y hugo

# 创建 Hugo 站点
hugo new site my-website
cd my-website

# 初始化 Git 并安装主题
git init
git submodule add https://github.com/CaiJimmy/hugo-theme-stack/ themes/hugo-theme-stack

# 创建示例内容
hugo new posts/my-first-post.md

# 生成静态文件
hugo

# 退出新用户会话
exit
EOF

echo "Hugo 已成功安装并配置在新用户 'website' 的路径下。"
