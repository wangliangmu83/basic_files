#!/data/data/com.termux/files/usr/bin/bash

# 定义log函数
log() {
    echo "$@"
}

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

# 定义设置密码的函数
set_user_password() {
    # 提示用户设置密码
    while true; do
        echo "请输入新密码:"
        read -s -p "" new_password
        echo
        echo "请再次输入密码:"
        read -s -p "" confirm_password
        echo
        
        if [ "$new_password" != "$confirm_password" ]; then
            echo "密码不匹配，请重新输入！"
        elif ! sudo passwd gitsync <<< "$new_password"; then
            echo "密码设置失败，请重新尝试。"
        else
            echo "密码设置成功!"
            break
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
    log "开始配置bash.bashrc"
    # 配置bash.bashrc
    local BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
    
    # 清空文件，确保从头开始配置
    > "$BASHRC_FILE"

    # 添加所有需要的行
    cat <<EOF >> "$BASHRC_FILE"
# 不保存重复的命令
shopt -s histappend
shopt -s histverify
export HISTCONTROL=ignoreboth

# 设置默认命令行提示符
PROMPT_DIRTRIM=2
PS1='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\$\[\e[0m\] '

# 处理不存在的命令
# 如果用户输入了不可用的命令，command-not-found 将给出包建议
if [ -x /data/data/com.termux/files/usr/libexec/termux/command-not-found ]; then
    command_not_found_handle() {
        /data/data/com.termux/files/usr/libexec/termux/command-not-found "\$1"
    }
fi

# 加载 Bash 自动补全
[ -r /data/data/com.termux/files/usr/share/bash-completion/bash_completion ] && . /data/data/com.termux/files/usr/share/bash-completion/bash_completion

# 显式设置 TERMUX_PREFIX
export TERMUX_PREFIX=/data/data/com.termux/files

#设置息屏保持服务
termux-wake-lock

# 启动 SSHD 服务（不输出信息）
/data/data/com.termux/files/usr/bin/sshd &>/dev/null

# 检查 proot-distro 是否已安装
if ! command -v proot-distro &> /dev/null; then
    echo "proot-distro 未安装，跳过相关操作..."
else
    # 检查 SSH 连接状态
    if [ -z "\$SSH_CONNECTION" ]; then
        # 本地登录，直接进入 Ubuntu
        echo "本地登录，直接进入 Ubuntu"
        proot-distro login ubuntu
    else
        # 检查是否有活动的 Ubuntu 会话
        if pgrep -f "proot.*-r.*ubuntu" > /dev/null; then
            echo "Termux 已登录到 Ubuntu"
            # 如果手机 Termux 已登录到 Ubuntu，则 SSH 连接也登录到 Ubuntu
            echo "尝试进入 Ubuntu 发行版"
            proot-distro login ubuntu
        else
            echo "Termux 未登录到 Ubuntu"
            # 如果手机 Termux 未登录到 Ubuntu，则 SSH 连接不登录到 Ubuntu
            echo "SSH 连接时不登录到 Ubuntu"
        fi
    fi
fi

# 打印 IN_UBUNTU 变量
echo "IN_UBUNTU: \${IN_UBUNTU:-未定义}"

# 在退出时清除 IN_UBUNTU 变量
trap 'unset IN_UBUNTU; echo "IN_UBUNTU 已清除"' EXIT
EOF

    log "bash.bashrc配置完成"
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
install_ubuntu
update_upgrade_packages
restart_ssh_service

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"