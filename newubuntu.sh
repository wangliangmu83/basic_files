#!/bin/bash

# 定义日志函数（假设已定义）
log() {
    echo "$@"
}

# 测试延迟的函数
check_latency() {
    local url=\$1
    local latency=$(ping -c 4 "$url" | tail -1 | awk -F '/' '{print \$5}')
    echo "$latency"
}

# 官方源和阿里云源
official_source="archive.ubuntu.com"
aliyun_source="mirrors.aliyun.com"

log "正在检查延迟..."

# 获取延迟
official_latency=$(check_latency "$official_source")
aliyun_latency=$(check_latency "$aliyun_source")

log "官方源延迟: $official_latency ms"
log "阿里云源延迟: $aliyun_latency ms"

# 比较延迟并决定是否切换源
if (( $(echo "$aliyun_latency < $official_latency" | bc -l) )); then
    log "切换APT源为阿里云镜像..."
    # 备份原有的sources.list文件
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo rm /etc/apt/sources.list

    # 写入阿里云镜像源到sources.list文件
    sudo tee /etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted
deb http://mirrors.aliyun.com/ubuntu/ jammy universe
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates universe
deb http://mirrors.aliyun.com/ubuntu/ jammy multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted
deb http://mirrors.aliyun.com/ubuntu/ jammy-security universe
deb http://mirrors.aliyun.com/ubuntu/ jammy-security multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    log "成功切换到阿里云镜像源。"
else
    log "阿里云源延迟不低于官方源，保持当前源不变。"
fi

# 更新并升级系统软件包
sudo apt update && sudo apt upgrade -y

log "安装必要的软件包..."
# 安装必要的软件包
sudo apt install -y vim openssh-server expect w3m w3m-img openssh-client openssl-tool

# 设置SSH服务开机自启
sudo systemctl enable ssh

# 生成所有类型的主机密钥
ssh-keygen -A

log "设置SSH密钥..."

# 定义SSH相关路径
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 创建SSH目录并设置权限
mkdir -p "$SSH_DIR" && sudo chmod 700 "$SSH_DIR"
# 创建authorized_keys文件并设置权限
touch "$AUTHORIZED_KEYS" && sudo chmod 600 "$AUTHORIZED_KEYS"

# 如果私钥或公钥文件不存在，则生成新的密钥对
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    # 显示确认消息
    read -p "No SSH keys found. Generate new keys? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo "Please enter a passphrase for your SSH private key:"
        read -s -p "Passphrase: " passphrase
        echo
        ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N "$passphrase"
        sudo chmod 600 "$PRIVATE_KEY"
        sudo chmod 644 "$PUBLIC_KEY"
    else
        log "SSH key generation cancelled."
    fi
else
    log "SSH keys already exist."
fi

# 如果公钥不在authorized_keys文件中，则追加公钥
if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
    cat "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" > /dev/null
    rm "$PUBLIC_KEY"
fi

# 修改sshd_config以允许密码登录
log "修改SSH配置以允许密码登录..."
# 删除含有 PasswordAuthentication 的所有行
sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
# 添加 PasswordAuthentication yes 到文件末尾
sudo sed -i '$ a\PasswordAuthentication yes' /etc/ssh/sshd_config

# 删除含有 PasswordAuthentication 的所有行
sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
# 添加 PasswordAuthentication yes 到文件末尾
sudo sed -i '$ a\PermitRootLogin yes' /etc/ssh/sshd_config


# 重启SSH服务
sudo systemctl restart ssh