#!/data/data/com.termux/files/usr/bin/bash
#换源
termux-change-repo
# 更新和升级软件包
apt update && apt upgrade -y

# 安装必要的软件包
pkg install vim openssh -y

# 设置存储权限
termux-setup-storage

# 生成主机密钥
ssh-keygen -A

# SSH 相关路径
USER=termux
SSH_DIR="/data/data/com.termux/files/home/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 删除可能存在的多余 .ssh 目录
rm -rf /data/data/com.termux/files/home/.ssh

# 创建 .ssh 目录，如果不存在
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
echo "检查目录: $SSH_DIR"
ls -ld "$SSH_DIR"

# 创建或准备 authorized_keys 文件
touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"
echo "检查文件: $AUTHORIZED_KEYS"
ls -ld "$AUTHORIZED_KEYS"

# 检查是否已存在 id_rsa 和 id_rsa.pub 文件
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    echo "未找到私钥或公钥，生成新的SSH密钥对..."
    ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N ""
    echo "检查生成的文件..."
    ls -l "$PRIVATE_KEY"
    ls -l "$PUBLIC_KEY"
    if [ -f "$PRIVATE_KEY" ]; then
        echo "私钥生成成功。"
        chmod 600 "$PRIVATE_KEY"
    else
        echo "生成私钥失败。"
    fi
    if [ -f "$PUBLIC_KEY" ]; then
        echo "公钥生成成功。"
        chmod 644 "$PUBLIC_KEY"
    else
        echo "生成公钥失败。"
    fi
else
    echo "SSH密钥对已存在。"
fi

# 将新生成的公钥添加到 authorized_keys 文件中
if ! grep -qF "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
    cat "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
fi

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"


