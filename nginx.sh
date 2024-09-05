#!/bin/bash

# 更新包列表并安装 Nginx
sudo apt-get update
sudo apt-get install -y nginx

# 配置 Nginx
sudo bash -c 'cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name bestwood.asia;

    root /home/website/my-website/public;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF'

# 测试 Nginx 配置
sudo nginx -t

# 重启 Nginx 服务
sudo systemctl restart nginx

echo "Nginx 已成功安装并配置。你现在可以通过 bestwood.asia 访问你的网站。"
