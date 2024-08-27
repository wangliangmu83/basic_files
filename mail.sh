#!/bin/bash

# 设置字符编码
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

install_mail_server() {
    # 更新系统
    sudo apt update && sudo apt upgrade -y

    # 修复依赖问题
    sudo apt install -y postfix
    sudo apt install --reinstall lsb-core
    sudo apt --fix-broken install
    sudo apt autoremove
    sudo apt clean

    # 检查并修复 snapd 问题
    sudo systemctl status snapd.mounts-pre.target || true
    sudo apt remove --purge -y snapd
    sudo apt install -y snapd
    sudo apt --fix-broken install
    sudo apt autoremove
    sudo apt clean

    # 安装必要的软件包，包括 Alpine
    sudo apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd openssl alpine ufw

    # 创建邮件存储目录
    sudo groupadd -g 5000 vmail
    sudo useradd -u 5000 -g vmail -s /usr/sbin/nologin -d /home/vmail -m vmail
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

    # 配置Postfix
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
smtputf8_enable = yes
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
    sudo openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.key -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=$myhostname"

    # 重启服务
    sudo systemctl restart postfix
    sudo systemctl restart dovecot

    # 检查并启用UFW
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw enable
    fi

    # 配置防火墙
    sudo ufw allow Postfix
    sudo ufw allow "Dovecot IMAP"
    sudo ufw allow "Dovecot POP3"

    echo "邮件服务器配置完成！"
}

install_mail_server
