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
        /data/data/com.termux/files/usr/libexec/termux/command-not-found "$1"
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
    if [ -z "$SSH_CONNECTION" ]; then
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
echo "IN_UBUNTU: ${IN_UBUNTU:-未定义}"

# 在退出时清除 IN_UBUNTU 变量
trap 'unset IN_UBUNTU; echo "IN_UBUNTU 已清除"' EXIT