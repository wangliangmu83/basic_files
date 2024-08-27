#!/bin/bash

# 更新系统并安装必要的软件包
sudo apt-get update
sudo apt-get install -y postfix dovecot-core dovecot-imapd dovecot-pop3d

# 配置Postfix
sudo tee /etc/postfix/main.cf > /dev/null <<EOL
myhostname = mail.bestwood.asia
mydomain = bestwood.asia
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
virtual_mailbox_domains = bestwood.asia
virtual_mailbox_base = /home/mail
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination
EOL

# 创建虚拟邮箱数据库
sudo tee /etc/postfix/vmailbox > /dev/null <<EOL
user1@bestwood.asia    bestwood.asia/user1/
user2@bestwood.asia    bestwood.asia/user2/
EOL

sudo postmap /etc/postfix/vmailbox

# 配置Dovecot
sudo tee /etc/dovecot/dovecot.conf > /dev/null <<EOL
protocols = imap pop3 lmtp
mail_location = maildir:/home/mail/%d/%n/Maildir
ssl = yes
ssl_cert = </etc/ssl/certs/mailserver.pem
ssl_key = </etc/ssl/private/mailserver.key

userdb {
  driver = passwd
}

passdb {
  driver = pam
}
EOL

# 重启Postfix和Dovecot服务
sudo systemctl restart postfix
sudo systemctl restart dovecot

# 配置防火墙
sudo ufw allow 587/tcp
sudo ufw allow 993/tcp
sudo ufw reload

echo "Postfix和Dovecot配置完成，并已重启服务。"
