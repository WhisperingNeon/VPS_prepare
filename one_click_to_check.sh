#!/bin/bash

echo "开始验证主机整备脚本的执行结果..."

# 1. 验证系统更新
echo "验证系统更新..."
if [ $(sudo apt list --upgradable 2>/dev/null | wc -l) -le 1 ]; then
    echo "系统已更新到最新版本。"
else
    echo "系统更新可能未完成，请检查。"
fi

# 2. 验证自动更新配置
echo "验证自动更新是否启用..."
if sudo systemctl is-enabled unattended-upgrades | grep -q "enabled"; then
    echo "自动更新已启用。"
else
    echo "自动更新未启用，请检查。"
fi

# 3. 验证基础工具安装
echo "验证基础工具安装..."
for pkg in ufw curl unzip docker nginx; do
    if dpkg -l | grep -q "^ii\s*$pkg"; then
        echo "$pkg 已安装。"
    else
        echo "$pkg 未安装，请检查。"
    fi
done

# 4. 验证 Docker 日志管理配置
echo "验证 Docker 日志管理配置..."
if [ -f /etc/docker/daemon.json ] && grep -q '"log-driver": "json-file"' /etc/docker/daemon.json; then
    echo "Docker 日志管理配置正确。"
else
    echo "Docker 日志管理配置错误，请检查 /etc/docker/daemon.json。"
fi

# 5. 验证新用户创建
echo "验证新用户创建..."
if id -u vmissss >/dev/null 2>&1; then
    echo "用户 vmissss 已创建。"
else
    echo "用户 vmissss 未创建，请检查。"
fi

# 6. 验证 SSH 配置
echo "验证 SSH 配置..."
if grep -q '^Port 22379' /etc/ssh/sshd_config; then
    echo "SSH 端口已设置为 22379。"
else
    echo "SSH 端口配置错误，请检查 /etc/ssh/sshd_config。"
fi

if grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config && grep -q '^PermitRootLogin prohibit-password' /etc/ssh/sshd_config; then
    echo "SSH 密码登录已禁用。"
else
    echo "SSH 密码登录配置错误，请检查 /etc/ssh/sshd_config。"
fi

# 验证 SSH 免密登录
echo "验证 SSH 免密登录..."
check_ssh_key() {
    local user=$1
    local home_dir=$2

    if [ -f "$home_dir/.ssh/authorized_keys" ]; then
        echo "$user 用户的 SSH 免密登录配置存在。"
    else
        echo "$user 用户的 SSH 免密登录配置缺失，请检查。"
    fi
}

check_ssh_key "root" "/root"
check_ssh_key "vmissss" "/home/vmissss"

# 7. 验证防火墙配置
echo "验证防火墙配置..."
if sudo ufw status | grep -q "22379"; then
    echo "SSH 端口 22379 已在防火墙中开放。"
else
    echo "SSH 端口 22379 未在防火墙中开放，请检查防火墙配置。"
fi

for port in 80 443; do
    if sudo ufw status | grep -q "$port"; then
        echo "端口 $port 已在防火墙中开放。"
    else
        echo "端口 $port 未在防火墙中开放，请检查防火墙配置。"
    fi
done

# 8. 验证时区设置
echo "验证时区设置..."
if timedatectl | grep -q "Asia/Shanghai"; then
    echo "时区已设置为上海。"
else
    echo "时区未设置为上海，请检查。"
fi

# 9. 验证 BRP 加速配置
echo "验证 BRP 加速配置..."
if [[ "$(sysctl -n net.core.default_qdisc 2>/dev/null)" == "fq" ]]; then
    echo "BRP 加速配置成功：net.core.default_qdisc = fq"
else
    echo "BRP 加速配置失败，请检查配置！"
fi
