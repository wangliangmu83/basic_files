#!/bin/bash

# 定义日志函数（假设已定义）
log() {
    echo "$@"
}

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
fi

log "配置sshd_config..."

# 定义sshd_config文件路径
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

# 定义要添加到sshd_config文件中的配置行
config_lines=(
    "PermitRootLogin yes"
    "ListenAddress 0.0.0.0"
    "PubkeyAuthentication yes"
    "AuthorizedKeysFile %h/.ssh/authorized_keys"
    "PasswordAuthentication no"  # 添加这一行来禁用密码认证
)

# 遍历配置行并添加到sshd_config文件中
for line in "${config_lines[@]}"; do
    if ! grep -q "^${line}$" "$SSHD_CONFIG_FILE"; then
        echo "${line}" | sudo tee -a "$SSHD_CONFIG_FILE" > /dev/null
    fi
done

# 开机启动ssh
sudo systemctl enable ssh

# 重启SSH服务
sudo systemctl restart ssh