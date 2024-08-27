#!/bin/bash

# 函数：安装邮件服务器
install_mail_server() {
    echo "正在更新系统..."
    sudo apt update && sudo apt upgrade -y

    # 检查并安装邮件传输代理
    if ! dpkg -l | grep -q postfix; then
        echo "正在安装 Postfix..."
        sudo apt install -y postfix
    else
        echo "Postfix 已安装，跳过安装。"
    fi

    # 修复依赖问题
    echo "修复依赖问题..."
    sudo apt install --reinstall lsb-core
    sudo apt --fix-broken install -y
    sudo apt autoremove -y
    sudo apt clean

    # 检查并修复 snapd 问题
    echo "检查 snapd..."
    if ! systemctl is-active --quiet snapd; then
        echo "正在重新安装 snapd..."
        sudo apt remove --purge -y snapd
        sudo apt install -y snapd
        sudo apt --fix-broken install -y
    fi

    # 安装必要的软件包
    echo "正在安装 Dovecot 和其他必要软件包..."
    sudo apt install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd openssl alpine ufw

    # 创建邮件存储目录
    echo "创建邮件存储目录..."
    sudo groupadd -g 5000 vmail || echo "组 vmail 已存在，跳过创建。"
    sudo useradd -u 5000 -g vmail -s /usr/sbin/nologin -d /home/vmail -m vmail || echo "用户 vmail 已存在，跳过创建。"
    sudo mkdir -p /home/mail
    sudo chown -R vmail:vmail /home/mail
    sudo chmod -R 770 /home/mail

    # 设置域名变量
    mydomain="bestwood.asia"
    myhostname="mail.bestwood.asia"

    # 检查域名变量
    if [[ -z "$mydomain" ]] || [[ -z "$myhostname" ]]; then
        echo "域名变量未设置或为空，请检查后重新运行脚本。"
        exit 1
    fi

    # 配置 Postfix
    echo "配置 Postfix..."
    sudo tee /etc/postfix/main.cf > /dev/null <<EOL
myhostname = $myhostname
mydomain = $mydomain
myorigin = /etc/mailname
inet_interfaces = all
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
relayhost =
mynetworks = 127.0.0.0/8
home_mailbox = Maildir/
smtpd_banner = \$myhostname ESMTP \$mail_name (Ubuntu)
smtpd_tls_cert_file=/etc/ssl/certs/mailserver.pem
smtpd_tls_key_file=/etc/ssl/private/mailserver.key
smtpd_use_tls=yes
virtual_mailbox_domains = $mydomain
virtual_mailbox_base = /home/mail
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
EOL

    # 配置 Dovecot
    echo "配置 Dovecot..."
    sudo tee /etc/dovecot/dovecot.conf > /dev/null <<EOL
protocols = imap pop3 lmtp
mail_location = maildir:/home/mail/%d/%n/Maildir
userdb {
  driver = passwd
}
passdb {
  driver = pam
}
EOL

    sudo tee /etc/dovecot/conf.d/10-mail.conf > /dev/null <<EOL
mail_location = maildir:/home/mail/%d/%n/Maildir
EOL

    sudo tee /etc/dovecot/conf.d/10-master.conf > /dev/null <<EOL
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}
EOL

    # 生成 SSL 证书
    echo "生成 SSL 证书..."
    sudo openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.key -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=$myhostname"

    # 重启服务
    echo "重启 Postfix 和 Dovecot..."
    sudo systemctl restart postfix
    sudo systemctl restart dovecot

    # 检查并启用 UFW
    echo "配置防火墙..."
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw enable
    fi

    # 配置防火墙规则
    sudo ufw allow Postfix
    sudo ufw allow "Dovecot IMAP"
    sudo ufw allow "Dovecot POP3"

    echo "邮件服务器配置完成！"
}

# 函数：卸载邮件服务器
uninstall_mail_server() {
    echo "停止 Postfix 和 Dovecot..."
    sudo systemctl stop postfix
    sudo systemctl stop dovecot

    echo "正在卸载邮件服务器软件包..."
    sudo apt remove --purge -y postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd alpine

    echo "删除配置文件和邮件存储目录..."
    sudo rm -rf /etc/postfix /etc/dovecot /home/mail /etc/ssl/certs/mailserver.pem /etc/ssl/private/mailserver.key

    sudo apt autoremove -y
    sudo apt clean

    echo "移除防火墙规则..."
    if ! sudo ufw status | grep -q "Status: inactive"; then
        sudo ufw delete allow Postfix
        sudo ufw delete allow "Dovecot IMAP"
        sudo ufw delete allow "Dovecot POP3"
        sudo ufw disable
    fi

    echo "邮件服务器已卸载！"
    exit 0
}

# 主菜单
echo "请选择一个选项："
echo "1. 安装邮件服务器"
echo "2. 卸载邮件服务器"
echo "3. 退出"
read -p "输入选项 (1/2/3): " choice

case $choice in
    1)
        install_mail_server
        ;;
    2)
        uninstall_mail_server
        ;;
    3)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效选项，请重新输入。"
        ;;
esac
