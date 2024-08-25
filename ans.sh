#!/data/data/com.termux/files/usr/bin/bash

# 配置sshd_config
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

# 配置bash.bashrc使得sshd服务自动启动
BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
SSHD_START_CMD="/data/data/com.termux/files/usr/bin/sshd"
UBUNTU_LOGIN_CMD="proot-distro login ubuntu"

# 添加启动SSHD服务的命令
if ! grep -q "# 启动SSHD服务" "$BASHRC_FILE"; then
    echo "# 启动SSHD服务" >> "$BASHRC_FILE"
fi

if ! grep -q "$SSHD_START_CMD" "$BASHRC_FILE"; then
    echo "$SSHD_START_CMD" >> "$BASHRC_FILE"
fi

# 添加进入Ubuntu的命令
if ! grep -q "if \[ -z \"\$SSH_CONNECTION\" \]; then" "$BASHRC_FILE"; then
    echo 'if [ -z "$SSH_CONNECTION" ]; then' >> "$BASHRC_FILE"
    echo '    if [ -z "$IN_UBUNTU" ]; then' >> "$BASHRC_FILE"
    echo '        echo "本地登录，进入Ubuntu"' >> "$BASHRC_FILE"
    echo '        export IN_UBUNTU=1' >> "$BASHRC_FILE"
    echo '        proot-distro login ubuntu' >> "$BASHRC_FILE"
    echo '    fi' >> "$BASHRC_FILE"
    echo 'else' >> "$BASHRC_FILE"
    echo '    if [ -n "$IN_UBUNTU" ]; then' >> "$BASHRC_FILE"
    echo '        echo "SSH连接，进入Ubuntu"' >> "$BASHRC_FILE"
    echo '        proot-distro login ubuntu' >> "$BASHRC_FILE"
    echo '    else' >> "$BASHRC_FILE"
    echo '        echo "SSH连接，保持在Termux"' >> "$BASHRC_FILE"
    echo '    fi' >> "$BASHRC_FILE"
    echo 'fi' >> "$BASHRC_FILE"
fi

# 重启SSH服务使配置生效
pkill -HUP sshd

# 提示信息
echo "SSH设置完成。您现在可以使用生成的密钥连接。"

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"
