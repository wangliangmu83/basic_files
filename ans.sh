#!/data/data/com.termux/files/usr/bin/bash

# 换源
termux-change-repo

# 更新和升级软件包
apt update && apt upgrade -y

# 安装必要的软件包
pkg install vim openssh -y

# 设置存储权限
termux-setup-storage
if [ $? -ne 0 ]; then
    echo "设置存储权限失败！"
    exit 1
fi

# SSH 相关路径
USER=termux
SSH_DIR="/data/data/com.termux/files/home/$USER/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 删除可能存在的多余 .ssh 目录
if [ -d "$SSH_DIR" ]; then
    rm -rf "$SSH_DIR"
fi

# 创建 .ssh 目录，如果不存在
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
echo "检查目录: $SSH_DIR"
ls -ld "$SSH_DIR" || { echo "无法创建或访问目录 $SSH_DIR"; exit 1; }

# 创建或准备 authorized_keys 文件
touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"
echo "检查文件: $AUTHORIZED_KEYS"
ls -ld "$AUTHORIZED_KEYS" || { echo "无法创建或访问文件 $AUTHORIZED_KEYS"; exit 1; }

# 检查是否已存在 id_rsa 和 id_rsa.pub 文件，并在需要时删除它们
if [ -f "$PRIVATE_KEY" ]; then
    rm -f "$PRIVATE_KEY"
    echo "私钥文件已被删除：$PRIVATE_KEY"
fi

if [ -f "$PUBLIC_KEY" ]; then
    rm -f "$PUBLIC_KEY"
    echo "公钥文件已被删除：$PUBLIC_KEY"
fi

# 检查是否已存在 id_rsa 和 id_rsa.pub 文件
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    echo "未找到私钥或公钥，生成新的SSH密钥对..."
    ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N ""
    echo "检查生成的文件..."
    ls -l "$PRIVATE_KEY" || { echo "生成私钥失败"; exit 1; }
    ls -l "$PUBLIC_KEY" || { echo "生成公钥失败"; exit 1; }
    chmod 600 "$PRIVATE_KEY"
    chmod 644 "$PUBLIC_KEY"
else
    echo "SSH密钥对已存在。"
fi

# 将新生成的公钥添加到 authorized_keys 文件中
if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
    cat "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    echo "公钥已添加到 $AUTHORIZED_KEYS"
    
    # 在公钥添加到 authorized_keys 后删除 id_rsa.pub
    if [ -f "$PUBLIC_KEY" ]; then
        rm -f "$PUBLIC_KEY"
        echo "公钥文件已被删除：$PUBLIC_KEY"
    fi
else
    echo "公钥已存在于 $AUTHORIZED_KEYS 中"
fi

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm -- "$0"
) &
echo "脚本将在5秒后删除。"