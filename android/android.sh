#!/data/data/com.termux/files/usr/bin/bash

# 定义函数
setup_termux_repo() {
    # 换源（假设 termux-change-repo 是一个可用的命令来切换Termux的仓库）
    termux-change-repo
}

update_upgrade_packages() {
    # 更新并升级现有的包
    apt update && apt upgrade -y
}

install_necessary_packages() {
    # 安装必要的软件包
    pkg install vim openssh proot-distro -y
}

generate_ssh_host_keys() {
    # 生成主机密钥
    ssh-keygen -A
}

configure_storage_permissions() {
    # 设置Termux的外部存储权限
    termux-setup-storage
    if [ $? -ne 0 ]; then
        echo "设置存储权限失败！"
        exit 1
    fi
}

setup_ssh_keys() {
    # SSH相关路径
    SSH_DIR="/data/data/com.termux/files/home/.ssh"
    AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
    PRIVATE_KEY="$SSH_DIR/id_rsa"
    PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

    # 创建 .ssh 目录，并设置权限
    mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
    touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"

    # 生成新的SSH密钥对
    if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
        ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N ""
        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"
    fi

    # 添加新生成的公钥到 authorized_keys 文件中
    if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
        cat "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    fi
}

set_user_password() {
    # 提示用户设置密码
    while true; do
        echo "请输入新密码:"
        passwd
        if [ $? -eq 0 ]; then
            echo "密码设置成功!"
            break
        else
            echo "密码设置失败，请重新尝试。"
        fi
    done
}

configure_sshd() {
    # 配置sshd_config
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

configure_bashrc() {
    # 配置bash.bashrc
    local BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
    local lines_to_add=(
        # ... (省略了与上面相同的部分)
    )

    for line in "${lines_to_add[@]}"; do
        if ! grep -q "^${line}$" "$BASHRC_FILE"; then
            echo "${line}" >> "$BASHRC_FILE"
        fi
    done
}

install_ubuntu() {
    # 安装ubuntu
    proot-distro install ubuntu
}

restart_ssh_service() {
    # 重启SSH服务使配置生效
    pkill -HUP sshd
}

# 执行配置任务
setup_termux_repo
update_upgrade_packages
install_necessary_packages
generate_ssh_host_keys
configure_storage_permissions
setup_ssh_keys
set_user_password
configure_sshd
configure_bashrc
restart_ssh_service
install_ubuntu
update_upgrade_packages

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"