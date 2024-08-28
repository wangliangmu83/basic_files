# 定义SSH相关路径
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

#删除原有的.ssh
rm -f "$SSH_DIR"/*

# 创建SSH目录并设置权限
mkdir -p "$SSH_DIR" && sudo chmod 700 "$SSH_DIR"
# 创建authorized_keys文件并设置权限
touch "$AUTHORIZED_KEYS" && sudo chmod 600 "$AUTHORIZED_KEYS"

# 如果私钥或公钥文件不存在，则生成新的密钥对
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
  # 显示确认消息
  read -p "No SSH keys found. Generate new keys? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    echo "Please enter a passphrase for your SSH private key:"
    read -s -p "Passphrase: " passphrase
    echo
    ssh-keygen -t rsa -b 4096 -C "king_rush@gmail.com" -f "$PRIVATE_KEY" -N
    sudo chmod 600 "$PRIVATE_KEY"
    sudo chmod 644 "$PUBLIC_KEY"
  else
    log "SSH key generation cancelled."
  fi
else
  log "SSH keys already exist."
fi

# 如果公钥不在authorized_keys文件中，则追加公钥
if ! grep -Fxq "$(cat "$PUBLIC_KEY")" "$AUTHORIZED_KEYS"; then
  cat "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" >/dev/null
  rm "$PUBLIC_KEY"
fi

cp "$AUTHORIZED_KEYS"
cp /root/.ssh/authorized_keys /home/gitsync/.ssh/authorized_keys

chown gitsync:gitsync /home/gitsync/.ssh/authorized_keys
chmod 600 /home/gitsync/.ssh/authorized_keys
