#!/bin/bash

# 函数：安装邮件服务器
install_mail_server() {
    # 更新系统
    sudo apt update && sudo apt upgrade -y

    # 安装必要的软件包
    sudo apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd openssl

    # 创建邮件存储目录
    sudo groupadd -g 5000 vmail
    sudo useradd -u 5000 -g vmail -s /usr/sbin/nologin -d /home/vmail -m vmail
    sudo mkdir -p /home/mail
    sudo chown -R vmail:vmail /home/mail
    sudo chmod -R 770 /home/mail

    # 配置Postfix
    sudo tee /etc/postfix/main.cf > /dev/null <<EOL
myhostname = mail.yourdomain.com
mydomain = yourdomain.com
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
virtual_mailbox_domains = yourdomain.com
virtual_mailbox_base = /home/mail
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
EOL

    # 配置Dovecot
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

    # 生成SSL证书
    sudo openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.key -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=mail.yourdomain.com"

    # 重启服务
    sudo systemctl restart postfix
    sudo systemctl restart dovecot

    # 配置防火墙
    sudo ufw allow Postfix
    sudo ufw allow "Dovecot IMAP"
    sudo ufw allow "Dovecot POP3"

    echo "邮件服务器配置完成！"
}

# 函数：卸载邮件服务器
uninstall_mail_server() {
    # 停止服务
    sudo systemctl stop postfix
    sudo systemctl stop dovecot

    # 卸载软件包
    sudo apt remove --purge -y postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd

    # 删除配置文件和邮件存储目录
    sudo rm -rf /etc/postfix /etc/dovecot /home/mail /etc/ssl/certs/mailserver.pem /etc/ssl/private/mailserver.key

    # 清理残留文件
    sudo apt autoremove -y
    sudo apt clean

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
