#!/bin/bash

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
sudo apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd openssl

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
EOL

# 配置Dovecot
sudo tee /etc/dovecot/dovecot.conf > /dev/null <<EOL
protocols = imap pop3 lmtp
mail_location = maildir:~/Maildir
EOL

sudo tee /etc/dovecot/conf.d/10-mail.conf > /dev/null <<EOL
mail_location = maildir:~/Maildir
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
sudo openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.key -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=mail.bestwood.asia"

# 重启服务
sudo systemctl restart postfix
sudo systemctl restart dovecot

# 配置防火墙
sudo ufw allow Postfix
sudo ufw allow "Dovecot IMAP"
sudo ufw allow "Dovecot POP3"

echo "邮件服务器配置完成！"
