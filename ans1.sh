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
    log "开始配置bash.bashrc"
    # 配置bash.bashrc
    local BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
    local lines_to_add=(
        "# 不保存重复的命令"
        "shopt -s histappend"
        "shopt -s histverify"
        "export HISTCONTROL=ignoreboth"

        # 设置默认命令行提示符
        PROMPT_DIRTRIM=2
        # 使用单引号来确保字符串中的空格和转义字符被正确处理
        PS1='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\$\[\e[0m\] '
               
        "# 处理不存在的命令"
        "if [ -x /data/data/com.termux/files/usr/libexec/termux/command-not-found ]; then"
        "    command_not_found_handle() {"
        "        /data/data/com.termux/files/usr/libexec/termux/command-not-found \"$1\""
        "    }; fi"  # 这里原本缺少一个换行和闭合的 }

        "# 加载 Bash 自动补全"
        "[ -r /data/data/com.termux/files/usr/share/bash-completion/bash_completion ] && . /data/data/com.termux/files/usr/share/bash-completion/bash_completion"

        "# 显式设置 TERMUX_PREFIX"
        "export TERMUX_PREFIX=/data/data/com.termux/files"

        "# 启动 SSHD 服务（不输出信息）"
        "/data/data/com.termux/files/usr/bin/sshd &>/dev/null"

        "# 检查 proot-distro 是否已安装"
        "if ! command -v proot-distro &> /dev/null; then"
        "    echo \"proot-distro 未安装，跳过相关操作...\""
        "else"
        "    # 检查 SSH 连接状态"
        "    if [ -z \"$SSH_CONNECTION\" ]; then"
        "        # 本地登录，直接进入 Ubuntu"
        "        echo \"本地登录，直接进入 Ubuntu\""
        "        proot-distro login ubuntu"
        "    else"
        "        # 检查是否有活动的 Ubuntu 会话"
        "        if pgrep -f \"proot.*-r.*ubuntu\" > /dev/null; then"
        "            echo \"Termux 已登录到 Ubuntu\""
        "            # 如果手机 Termux 已登录到 Ubuntu，则 SSH 连接也登录到 Ubuntu"
        "            echo \"尝试进入 Ubuntu 发行版\""
        "            proot-distro login ubuntu"
        "        else"
        "            echo \"Termux 未登录到 Ubuntu\""
        "            # 如果手机 Termux 未登录到 Ubuntu，则 SSH 连接不登录到 Ubuntu"
        "            echo \"SSH 连接时不登录到 Ubuntu\""
        "        fi"
        "    fi"
        "fi"  # 缺失的闭合 }

        "# 打印 IN_UBUNTU 变量"
        "echo \"IN_UBUNTU: \${IN_UBUNTU:-未定义}\""

        "# 在退出时清除 IN_UBUNTU 变量"
        "trap 'unset IN_UBUNTU; echo \"IN_UBUNTU 已清除\"' EXIT"
    )

    for line in "${lines_to_add[@]}"; do
        if ! grep -qF -- "${line}" "$BASHRC_FILE"; then
            echo "${line}" >> "$BASHRC_FILE"
        fi
    done
    log "bash.bashrc配置完成"
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