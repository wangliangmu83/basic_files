#!/bin/bash

# 下载git.sh.enc
curl https://raw.githubusercontent.com/wangliangmu83/basic_files/main/android/git.sh.enc >git.sh.enc
    
# 输入密码解密文件
openssl aes-256-cbc -d -pbkdf2 -in git.sh.enc -out git.sh    
    
# 授权git.sh
chmod +x git.sh

echo 'git.sh下载成功'    

# 执行git.sh
./git.sh