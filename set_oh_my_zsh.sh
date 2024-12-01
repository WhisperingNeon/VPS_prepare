#!/bin/bash

# 一键优化终端使用脚本
# 适用于 Ubuntu 22

set -e

echo "=== 开始优化终端 ==="

# 1. 更新系统并安装 Zsh
echo "更新系统并安装 Zsh..."
sudo apt update && sudo apt install -y zsh git curl wget

# 2. 安装 Oh My Zsh
echo "安装 Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh 已安装，跳过安装步骤..."
fi

# 3. 设置 Zsh 为默认 Shell
echo "设置 Zsh 为默认 Shell..."
chsh -s $(which zsh)

# 4. 安装 Powerlevel10k 主题
echo "安装 Powerlevel10k 主题..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> ~/.zshrc
else
    echo "Powerlevel10k 主题已安装，跳过..."
fi

# 5. 安装常用插件 (zsh-autosuggestions, zsh-syntax-highlighting)
echo "安装常用插件..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS=("$ZSH_CUSTOM/plugins/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting")

# 安装 zsh-autosuggestions
if [ ! -d "${PLUGINS[0]}" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${PLUGINS[0]}
else
    echo "zsh-autosuggestions 已安装，跳过..."
fi

# 安装 zsh-syntax-highlighting
if [ ! -d "${PLUGINS[1]}" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${PLUGINS[1]}
else
    echo "zsh-syntax-highlighting 已安装，跳过..."
fi

# 更新 .zshrc 插件配置
echo "更新 .zshrc 插件配置..."
sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' ~/.zshrc

# 6. 安装字体 (Nerd Fonts)
echo "安装 Nerd Fonts..."
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR" ]; then
    mkdir -p "$FONT_DIR"
fi
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
wget -O Hack.zip "$NERD_FONT_URL"
unzip Hack.zip -d "$FONT_DIR"
rm Hack.zip
fc-cache -fv

# 7. 应用配置
echo "应用配置..."
source ~/.zshrc

echo "=== 终端优化完成！请重新启动终端以体验新环境 ==="
