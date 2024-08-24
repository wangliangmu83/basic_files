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

# 启动SSH服务
sshd &

# 提示用户设置密码
echo "请为当前用户设置新密码:"
passwd

# 配置bash.bashrc使得sshd服务自动启动
echo "# 启动SSHD服务" >> /data/data/com.termux/files/usr/etc/bash.bashrc
echo "/data/data/com.termux/files/usr/bin/sshd" >> /data/data/com.termux/files/usr/etc/bash.bashrc

# 重新加载bash.bashrc
source /data/data/com.termux/files/usr/etc/bash.bashrc

# 配置sshd_config
echo "配置sshd_config..."
echo "PermitRootLogin yes" > /data/data/com.termux/files/usr/etc/ssh/sshd_config
echo "ListenAddress 0.0.0.0" >> /data/data/com.termux/files/usr/etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /data/data/com.termux/files/usr/etc/ssh/sshd_config

# 重启SSH服务使配置生效
pkill -HUP sshd

# 在子shell中删除脚本自身
(
    sleep 5  # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
echo "脚本将很快被删除。"


