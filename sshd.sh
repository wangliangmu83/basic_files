# 定义SSH相关路径
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# 创建SSH目录并设置权限
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
# 创建authorized_keys文件并设置权限
touch "$AUTHORIZED_KEYS" && chmod 600 "$AUTHORIZED_KEYS"

# 如果私钥或公钥文件不存在，则生成新的密钥对
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
  read -p "No SSH keys found. Generate new keys? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    echo "Generating SSH keys without a passphrase."
    ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N ""
    chmod 600 "$PRIVATE_KEY"
    chmod 644 "$PUBLIC_KEY"
  else
    echo "SSH key generation cancelled."
  fi
else
  echo "SSH keys already exist."
fi

# 如果公钥不在authorized_keys文件中，则追加公钥
if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
  cat "$PUBLIC_KEY" | tee -a "$AUTHORIZED_KEYS" >/dev/null
  # 不删除公钥文件
fi

# 复制 authorized_keys 到 gitsync 用户
cp "$AUTHORIZED_KEYS" /home/gitsync/.ssh/authorized_keys

# 设置权限
chown gitsync:gitsync /home/gitsync/.ssh/authorized_keys
chmod 600 /home/gitsync/.ssh/authorized_keys
