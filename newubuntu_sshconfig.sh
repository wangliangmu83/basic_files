#!/bin/bash

# 定义sshd_config文件路径
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

# 定义要添加到sshd_config文件中的配置行
config_lines=(
    "PermitRootLogin prohibit-password"
    "ListenAddress 0.0.0.0"
    "PubkeyAuthentication yes"
    "AuthorizedKeysFile %h/.ssh/authorized_keys"
    "PasswordAuthentication no"
)

# 遍历配置行并添加到sshd_config文件中
for line in "${config_lines[@]}"; do
    if ! grep -q "^${line}$" "$SSHD_CONFIG_FILE"; then
        echo "${line}" | sudo tee -a "$SSHD_CONFIG_FILE" >/dev/null
    fi
done

# 开机启动ssh
sudo systemctl enable ssh

# 重启SSH服务
sudo systemctl restart ssh

# 在子shell中删除脚本自身
(
    sleep 5 # 等待一段时间让脚本完全执行完毕
    rm "$0"
) &
