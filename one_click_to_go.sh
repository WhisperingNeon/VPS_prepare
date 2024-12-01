#!/bin/bash


#ubuntu主机整备脚本

exec > >(tee -i /var/log/one_click_to_go.log)
exec 2>&1

echo "开始执行脚本..."

# 1. 软件更新
echo "更新系统软件..."
sudo apt update -y && sudo apt upgrade -y

# 2.常规安全更新
echo "设置自动更新..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# 3. 安装基础工具 ufw, curl, unzip, docker, nginx
echo "安装基础工具..."
sudo apt install -y ufw curl unzip nginx
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# 设置docker日志管理
echo "docker日志管理"
sudo mkdir -p /etc/docker
cat << 'EOF' | sudo tee /etc/docker/daemon.json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "3",
        "max-size": "10m"
    }
}
EOF
echo "重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# 4. 添加新用户
echo "添加新用户"
username="vmissss"
password="xC6/rU7+uO6!zY"
useradd -m -s /bin/bash -G sudo "$username"
# 设置用户密码
echo "$username:$password" | chpasswd

# 5. 修改 SSH 端口为 22379
echo "修改 SSH 端口为 22379..."
sudo sed -i 's/^#Port 22/Port 22379/' /etc/ssh/sshd_config
sudo systemctl restart sshd.service

# 6. 设置账户SSH 免密登录
public_key_root="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSmXFCOHzhxWMCahXFc+yOeOPmZOersckVy8MYAi4WPp3a0Lv3QlMg7PcR7mCmtxB/3zcmKJRf3MZ7+7jdLbKM0woOjxBgdUBf+ZgIGfukFUmYNOixY4ASwWlHs/2eMIrSfTjBXkDKOVL+WLgLeCktWr3zoKgSofWR5rFadD9QoHh/jZJa8SxX8ZNlxgcvdi1ihDxC05bI+PpAIKlBoKnBWL3fShzCBvnL1CtTg2+lrq9/3g+NuitKSb48ATayDo7jj/QMDKxHritSIxLQphKLiqZhuqZDWvMcZieLp7HT2X3OLukZP43voxzA5nXFJyR4AovI+jMXVum/vo++9G1DzjqbilH8N7DAUmo1jORrbuGdSmPx4QU2QtkErqdexoyglzOHo2A5/pFJ6cdYDtQ9BlEQoHuVHJsLyczIGWRJYRZiLVRaLW+POZ20RKgoQpcUOTcQloRWZx2OtyPuvjnAyHQKgXmWfagdracSi4NFsaCUCXAQTZHGnHqN+F0nLjU0/WpGlk8HJDqq0qL7dYNfdiZWKJTQ1wGXDqQgjFevVbw51U4kiUw/mjjK3f27Ac7FJ3zlyo/BBRrXpkx5nTSv9WRux6SW8UB5l+p3R4+52XnBDOq4csJcO1t4xzOagTsCY1lDxG9xaTGCJ8q5sXVTOmBi0fHn8+S8buv6VxMbqQ== tbw@LAPTOP-J12MDU2F"
public_key_vmissss="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDR/lj5L+yCZaqJLSi8SCcExew+T+I4sGpUY2xs4xoir08DSHseBdrdDoon4lM+cmgpFYNeDVwlDlYut+mOR5uwc+JB+C4twyCSCTZJT3SQ7lvcgn1EnRHqfuzWJ8a5UYx7Kn4ktowmz0RUlSyBK6p/S/Z2Zges6VRptnnLk9n4ot25spTI3CKBH3DhRxMXjPsBVucHjFkBKGrrbb1z5buCofYdH15kXlqbVyH6cCWQ/tlhSei1sIohlTp7JxpRg8MSFsFfOzfOkHxBAVsrj61gvSGKgVXTL0udojVdhdqQuW6p4IyWPcziPq0Kofa1/33525JDAsARPVG/O0/9Rk0M0RXegOfZ2i8RpdmBiC+MK0q96N/UhSrAKMWIDpM/R1Ee8f1TwqO03t8FQmHEJ7FXmMHBydWXPynF8FJmlNtFybPoj0Rt9Qv3o6F/UPcdCK8CfNKxsWcpmLYP2O4HuW8qGIufpLSH9rbtXPq2KqtRFeYB7uTjKZ1AsNuBIwd4Yp5yyGTDVJRDwhwjJR9gZoqfPdpqUKz9rbJOBhHJSeKMHf3ucI5OHNnWKMmHj3D05ZI+4wFx1TDx4PkD1oEfz0GciSho6K+1rGIaDHMgTjSfvtWsLn7XXHM72UcPLPYGIGvPoeWz7cpCbxZjgnj6tzmAsFYD/FaGc4bLCSm72/qY3Q== tbw@LAPTOP-J12MDU2F"
echo "设置 root&vmissss SSH 免密登录..."
setup_ssh_key() {
    local user=$1
    local home_dir=$2
    local pub_key=$3

    echo "为 $user 用户配置 SSH 免密登录..."

    # 确保用户的 .ssh 目录存在
    sudo mkdir -p $home_dir/.ssh

    # 写入公钥到 authorized_keys
    echo "$pub_key" | sudo tee $home_dir/.ssh/authorized_keys > /dev/null

    # 设置权限
    sudo chmod 700 $home_dir/.ssh
    sudo chmod 600 $home_dir/.ssh/authorized_keys
    sudo chown -R $user:$user $home_dir/.ssh

    echo "$user 用户的 SSH 免密登录配置完成。"
}

# 为 root 用户配置免密登录
setup_ssh_key "root" "/root" "$public_key_root"

# 为 vmissss 用户配置免密登录
setup_ssh_key "vmissss" "/home/vmissss" "$public_key_vmissss"

# 修改 SSH 配置文件以禁用密码登录
echo "修改 SSH 配置以禁用密码登录..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# 确保允许使用公钥认证
if ! grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config; then
    echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

# 重启 SSH 服务
echo "重启 SSH 服务以应用更改..."
sudo systemctl restart sshd.service


# 7. 设置 UFW 防火墙开放端口
echo "设置 UFW 防火墙开放端口..."
sudo ufw allow 22379/tcp    # 允许新的 SSH 端口
sudo ufw allow 80/tcp       # 允许 HTTP
sudo ufw allow 443/tcp      # 允许 HTTPS
sudo ufw enable
sudo ufw status

# 8. 设置时区为上海
echo "设置时区为上海..."
sudo timedatectl set-timezone Asia/Shanghai

# 9. 配置 BRP 加速（示例：安装并配置 BRP 加速工具）
echo "配置 BRP 加速..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p


echo "主机整备完成！"


