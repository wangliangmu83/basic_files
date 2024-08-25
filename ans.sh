#!/data/data/com.termux/files/usr/bin/bash

# 换源（假设 termux-change-repo 是一个可用的命令来切换Termux的仓库）
termux-change-repo

# 更新并升级现有的包
apt update && apt upgrade -y

# 安装必要的软件包
pkg install vim openssh -y

# 设置Termux的外部存储权限
termux-setup-storage
if [ $? -ne 0 ]; then
    echo "设置存储权限失败！"
    exit 1
fi

# SSH相关路径
SSH_DIR="/data/data/com.termux/files/home/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 如果SSH目录存在，则删除它
if [ -d "$SSH_DIR" ]; then
    rm -rf "$SSH_DIR"
fi

# 创建 .ssh 目录，并设置权限
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
echo "检查目录: $SSH_DIR"
ls -ld "$SSH_DIR" || { echo "无法创建或访问目录 $SSH_DIR"; exit 1; }

# 准备 authorized_keys 文件
touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"
echo "检查文件: $AUTHORIZED_KEYS"
ls -ld "$AUTHORIZED_KEYS" || { echo "无法创建或访问文件 $AUTHORIZED_KEYS"; exit 1; }

# 如果密钥文件存在，删除它们
for key in "$PRIVATE_KEY" "$PUBLIC_KEY"; do
    if [ -f "$key" ]; then
        rm -f "$key"
        echo "${key##*/} 文件已被删除：$key"
    fi
done

# 生成新的SSH密钥对
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

# 添加新生成的公钥到 authorized_keys 文件中
if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
    cat "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    echo "公钥已添加到 $AUTHORIZED_KEYS"
else
    echo "公钥已存在于 $AUTHORIZED_KEYS 中"
fi

# 启动SSH服务
sshd &

# 提示用户设置密码
echo "请为当前用户设置新密码:"
passwd

# 重启SSH服务使配置生效
pkill -HUP sshd

# 在子shell中延迟删除脚本自身
(
    sleep 5  # 给脚本执行完成留出时间
    rm -- "$0"
) &
echo "脚本将在5秒后删除。"