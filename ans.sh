#!/data/data/com.termux/files/usr/bin/bash

# 配置sshd_config
echo "配置sshd_config..."
echo "PermitRootLogin yes" > /data/data/com.termux/files/usr/etc/ssh/sshd_config
echo "ListenAddress 0.0.0.0" >> /data/data/com.termux/files/usr/etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /data/data/com.termux/files/usr/etc/ssh/sshd_config

# 配置bash.bashrc使得sshd服务自动启动
echo "# 启动SSHD服务" >> /data/data/com.termux/files/usr/etc/bash.bashrc
echo "/data/data/com.termux/files/usr/bin/sshd" >> /data/data/com.termux/files/usr/etc/bash.bashrc

# 重新加载bash.bashrc
source /data/data/com.termux/files/usr/etc/bash.bashrc

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


