#!/data/data/com.termux/files/usr/bin/bash
# 换源（假设 termux-change-repo 是一个可用的命令来切换Termux的仓库）
termux-change-repo

# 更新并升级现有的包
apt update && apt upgrade -y

# 安装必要的软件包
pkg install vim openssh -y

# 生成主机密钥
ssh-keygen -A

# 设置Termux的外部存储权限
termux-setup-storage
if [ $? -ne 0 ]; then
    echo "设置存储权限失败！"
    exit 1
fi

#配置sshd_config
echo "配置sshd_config..."
SSHD_CONFIG_FILE="/data/data/com.termux/files/usr/etc/ssh/sshd_config"

# 检查并添加配置项
if ! grep -q "^PermitRootLogin yes" "$SSHD_CONFIG_FILE"; then
    echo "PermitRootLogin yes" >> "$SSHD_CONFIG_FILE"
fi

if ! grep -q "^ListenAddress 0.0.0.0" "$SSHD_CONFIG_FILE"; then
    echo "ListenAddress 0.0.0.0" >> "$SSHD_CONFIG_FILE"
fi

if ! grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG_FILE"; then
    echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG_FILE"
fi

if ! grep -q "^AuthorizedKeysFile /data/data/com.termux/files/home/.ssh/authorized_keys" "$SSHD_CONFIG_FILE"; then
    echo "AuthorizedKeysFile /data/data/com.termux/files/home/.ssh/authorized_keys" >> "$SSHD_CONFIG_FILE"
fi

if ! grep -q "^PasswordAuthentication no" "$SSHD_CONFIG_FILE"; then
    echo "PasswordAuthentication no" >> "$SSHD_CONFIG_FILE"
fi

# 配置bash.bashrc使得sshd服务自动启动
BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
SSHD_START_CMD="/data/data/com.termux/files/usr/bin/sshd"
UBUNTU_LOGIN_CMD="proot-distro login ubuntu"

if ! grep -q "# 启动SSHD服务" "$BASHRC_FILE"; then
    echo "# 启动SSHD服务" >> "$BASHRC_FILE"
fi

if ! grep -q "$SSHD_START_CMD" "$BASHRC_FILE"; then
    echo "$SSHD_START_CMD" >> "$BASHRC_FILE"
fi

if ! grep -q "$UBUNTU_LOGIN_CMD" "$BASHRC_FILE"; then
    echo "$UBUNTU_LOGIN_CMD" >> "$BASHRC_FILE"
fi

# 启动SSH服务
sshd &

#开始建立密钥
# SSH相关路径
SSH_DIR="/data/data/com.termux/files/home/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 如果SSH目录存在，则删除它
rm -rf "$SSH_DIR"

# 创建 .ssh 目录，并设置权限
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
echo "检查目录: $SSH_DIR"
ls -ld "$SSH_DIR" || { echo "无法创建或访问目录 $SSH_DIR"; exit 1; }

# 准备 authorized_keys 文件
touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"
echo "检查文件: $AUTHORIZED_KEYS"
ls -ld "$AUTHORIZED_KEYS" || { echo "无法创建或访问文件 $AUTHORIZED_KEYS"; exit 1; }

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


# 提示用户设置密码
echo "请为当前用户设置新密码:"
# 一直循环，直到密码设置成功
while true; do
    echo "请输入新密码:"
    passwd

    # 检查passwd命令的退出状态码
    if [ $? -eq 0 ]; then
        echo "密码设置成功!"
        break # 密码设置成功后退出循环
    else
        echo "密码设置失败，请重新尝试。"
    fi
done

# 重启SSH服务使配置生效
pkill -HUP sshd

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"


