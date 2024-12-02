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
username="user"
password="user_pwd"
sudo adduser --disabled-password --gecos "" "$username"
echo "$username:$password" | sudo chpasswd
sudo usermod -aG sudo "$username"


# 5. 修改 SSH 端口为
echo "修改 SSH 端口为 8000"
sudo sed -i 's/^#Port 22/Port 8000/' /etc/ssh/sshd_config
sudo systemctl restart sshd.service

# 6. 设置账户SSH 免密登录
public_key_root="pubkey"
public_key_user="pubkey"
echo "设置 root&user SSH 免密登录..."
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

# 为 user 用户配置免密登录
setup_ssh_key "user" "/home/user" "$public_key_user"

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
sudo ufw allow 8000/tcp    # 允许新的 SSH 端口
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


