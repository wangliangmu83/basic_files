#!/bin/bash

# 函数：添加邮件账户
add_user() {
    read -p "请输入要添加的用户名: " username
    read -s -p "请输入密码: " password
    echo
    sudo useradd -m -s /usr/sbin/nologin $username
    echo "$username:$password" | sudo chpasswd
    sudo mkdir -p /home/mail/bestwood.asia/$username/Maildir
    sudo chown -R vmail:vmail /home/mail/bestwood.asia/$username
    sudo chmod -R 770 /home/mail/bestwood.asia/$username
    echo "用户 $username 已添加。"
}

# 函数：删除邮件账户
delete_user() {
    read -p "请输入要删除的用户名: " username
    sudo userdel -r $username
    sudo rm -rf /home/mail/bestwood.asia/$username
    echo "用户 $username 已删除。"
}

# 主菜单
while true; do
    echo "请选择一个选项："
    echo "1. 添加邮件账户"
    echo "2. 删除邮件账户"
    echo "3. 退出"
    read -p "输入选项 (1/2/3): " choice

    case $choice in
    1)
        add_user
        ;;
    2)
        delete_user
        ;;
    3)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效选项，请重新输入。"
        ;;
    esac
done
