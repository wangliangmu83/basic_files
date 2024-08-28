#!/bin/bash

# 定义日志函数
log() {
    echo "$@"
}

check_latency() {
    local source="$1"
    local ping_result
    ping_result=$(ping -c 4 "$source" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "获取延迟失败，请检查网络连接或源地址。"
        return 1
    fi

    # 使用 awk 获取延迟
    latency=$(echo "$ping_result" | awk -F'/' 'END {print $(NF-1)}')
    echo "$latency"
}

# 定义源地址
official_source="archive.ubuntu.com"
aliyun_source="mirrors.aliyun.com"

echo "正在检查延迟..."
official_latency=$(check_latency "$official_source")
aliyun_latency=$(check_latency "$aliyun_source")

if [ -n "$official_latency" ] && [ -n "$aliyun_latency" ]; then
    echo "官方源延迟: $official_latency ms"
    echo "阿里云源延迟: $aliyun_latency ms"

    if (($(echo "$aliyun_latency < $official_latency" | bc -l))); then
        echo "切换到阿里云源"
        # 切换源的命令
    else
        echo "保持使用官方源"
    fi
else
    echo "获取延迟失败，请检查网络连接或源地址。"
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
        ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N
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
    cat "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" >/dev/null
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

# 在子shell中删除脚本自身
(
    sleep 5 # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
