#!/data/data/com.termux/files/usr/bin/bash

# 配置sshd_config
configure_sshd() {
    local SSHD_CONFIG_FILE="/data/data/com.termux/files/usr/etc/ssh/sshd_config"
    local config_lines=(
        "PermitRootLogin yes"
        "ListenAddress 0.0.0.0"
        "PubkeyAuthentication yes"
        "AuthorizedKeysFile /data/data/com.termux/files/home/.ssh/authorized_keys"
    )

    for line in "${config_lines[@]}"; do
        if ! grep -q "^${line}$" "$SSHD_CONFIG_FILE"; then
            echo "${line}" >> "$SSHD_CONFIG_FILE"
        fi
    done
}

# 配置bash.bashrc使得sshd服务自动启动
configure_bashrc() {
    local BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
    local SSHD_START_CMD="/data/data/com.termux/files/usr/bin/sshd"
    local UBUNTU_LOGIN_CMD="proot-distro login ubuntu"

    local bashrc_content=(
        '# 启动SSHD服务'
        "${SSHD_START_CMD}"
        'if [ -z "$SSH_CONNECTION" ]; then'
        '    if [ -z "$IN_UBUNTU" ]; then'
        '        echo "本地登录，进入Ubuntu"'
        '        export IN_UBUNTU=1'
        '        ${UBUNTU_LOGIN_CMD}'
        '    fi'
        'else'
        '    if [ -n "$IN_UBUNTU" ]; then'
        '        echo "SSH连接，进入Ubuntu"'
        '        ${UBUNTU_LOGIN_CMD}'
        '    else'
        '        echo "SSH连接，保持在Termux"'
        '    fi'
        'fi'
    )

    if ! grep -q "^# 启动SSHD服务$" "$BASHRC_FILE"; then
        echo "${bashrc_content[@]}" >> "$BASHRC_FILE"
    fi
}

# 执行配置任务
configure_sshd
configure_bashrc

# 重启SSH服务使配置生效
pkill -HUP sshd

# 提示信息
echo "SSH设置完成。您现在可以使用生成的密钥连接。"

# 删除脚本自身
rm -- "$0"
echo "脚本已删除。"