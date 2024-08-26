#!/bin/bash
curl -O https://www.openssl.org/source/openssl-1.1.1.tar.gz
tar -xzf openssl-1.1.1.tar.gz
cd openssl-1.1.1
./config --prefix=$HOME/openssl --openssldir=$HOME/openssl
make
make install
export PATH=$HOME/openssl/bin:$PATH
export LD_LIBRARY_PATH=$HOME/openssl/lib:$LD_LIBRARY_PATH
openssl version

# 下载git.sh.enc
curl https://raw.githubusercontent.com/wangliangmu83/basic_files/main/android/git.sh.enc >git.sh.enc
    
# 输入密码解密文件
openssl aes-256-cbc -d -pbkdf2 -in git.sh.enc -out git.sh    
    
# 授权git.sh
chmod +x git.sh

echo 'git.sh下载成功'    

# 执行git.sh
./git.sh