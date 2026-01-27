#!/bin/bash

# Linux开发环境一键卸载工具
# 用于卸载和清理Neovim和Tmux（仅清理通过setup-env.sh安装的内容）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 系统检测函数
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

get_package_manager() {
    case $1 in
        ubuntu|debian)
            echo "apt"
            ;;
        centos|rhel|fedora)
            echo "dnf"
            ;;
        arch|manjaro)
            echo "pacman"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Neovim卸载函数
uninstall_neovim() {
    local pkg_manager=$1

    log_info "准备卸载Neovim..."

    # 备份配置
    if [ -d "$HOME/.config/nvim" ]; then
        local backup_dir="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        cp -r "$HOME/.config/nvim" "$backup_dir"
        log_info "Neovim配置已备份到: $backup_dir"
    else
        log_info "Neovim配置目录不存在，跳过备份"
    fi

    # 卸载程序
    if command -v nvim &> /dev/null; then
        log_info "正在卸载Neovim程序..."
        case $pkg_manager in
            apt)
                sudo apt remove --purge -y neovim
                sudo apt autoremove -y
                ;;
            dnf)
                sudo dnf remove -y neovim
                ;;
            pacman)
                sudo pacman -Rns --noconfirm neovim
                ;;
            *)
                log_error "不支持的包管理器: $pkg_manager"
                return 1
                ;;
        esac
        log_info "Neovim程序已卸载"
    else
        log_info "Neovim程序未安装，跳过卸载"
    fi

    # 删除配置和数据目录
    local nvim_dirs=(
        "$HOME/.config/nvim"
        "$HOME/.local/share/nvim"
        "$HOME/.cache/nvim"
        "$HOME/.local/state/nvim"
    )

    log_info "清理Neovim相关目录..."
    for dir in "${nvim_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log_info "已删除: $dir"
        else
            log_info "目录不存在，跳过: $dir"
        fi
    done

    log_info "Neovim卸载完成"
    return 0
}

# Tmux卸载函数
uninstall_tmux() {
    local pkg_manager=$1

    log_info "准备卸载Tmux..."

    # 备份配置
    if [ -f "$HOME/.tmux.conf" ]; then
        local backup_file="$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
        cp "$HOME/.tmux.conf" "$backup_file"
        log_info "Tmux配置已备份到: $backup_file"
    else
        log_info "Tmux配置文件不存在，跳过备份"
    fi

    # 卸载程序
    if command -v tmux &> /dev/null; then
        log_info "正在卸载Tmux程序..."
        case $pkg_manager in
            apt)
                sudo apt remove --purge -y tmux
                sudo apt autoremove -y
                ;;
            dnf)
                sudo dnf remove -y tmux
                ;;
            pacman)
                sudo pacman -Rns --noconfirm tmux
                ;;
            *)
                log_error "不支持的包管理器: $pkg_manager"
                return 1
                ;;
        esac
        log_info "Tmux程序已卸载"
    else
        log_info "Tmux程序未安装，跳过卸载"
    fi

    # 删除配置文件
    if [ -f "$HOME/.tmux.conf" ]; then
        rm -f "$HOME/.tmux.conf"
        log_info "已删除Tmux配置文件"
    else
        log_info "Tmux配置文件不存在，跳过删除"
    fi

    log_info "Tmux卸载完成"
    return 0
}

# 主函数
main() {
    log_info "=========================================="
    log_info "  开发环境清理工具"
    log_info "=========================================="
    log_info ""
    log_warn "此工具将卸载以下内容："
    log_warn "  - Neovim (程序 + 配置 + 数据)"
    log_warn "  - Tmux (程序 + 配置)"
    log_info ""
    log_info "以下内容将被保留："
    log_info "  + 编程语言环境 (Python, Go, Rust, Node.js)"
    log_info "  + 包管理工具 (pip, cargo, npm等)"
    log_info "  + zsh和oh-my-zsh"
    log_info "  + Git"
    log_info "  + Docker"
    log_info ""

    # 要求用户确认
    echo -n "确认卸载? (yes/no): "
    read -r confirm
    echo ""

    if [ "$confirm" != "yes" ]; then
        log_info "取消卸载"
        exit 0
    fi

    # 检测系统
    distro=$(detect_distro)
    pkg_manager=$(get_package_manager "$distro")

    if [ "$pkg_manager" = "unknown" ]; then
        log_error "不支持的系统: $distro"
        log_error "支持的系统: Ubuntu/Debian, CentOS/RHEL, Arch Linux"
        exit 1
    fi

    log_info "检测到系统: $distro"
    log_info "使用包管理器: $pkg_manager"
    log_info ""

    # 验证sudo权限
    if ! sudo -v &> /dev/null; then
        log_error "需要sudo权限才能卸载程序"
        exit 1
    fi

    # 卸载组件
    log_step "开始卸载Neovim..."
    if uninstall_neovim "$pkg_manager"; then
        log_info "✓ Neovim卸载成功"
    else
        log_error "✗ Neovim卸载失败"
    fi

    log_info ""
    log_step "开始卸载Tmux..."
    if uninstall_tmux "$pkg_manager"; then
        log_info "✓ Tmux卸载成功"
    else
        log_error "✗ Tmux卸载失败"
    fi

    # 完成提示
    log_info ""
    log_info "=========================================="
    log_info "  清理完成！"
    log_info "=========================================="
    log_info "如需重新安装，请运行: ./setup-env.sh"
    log_info ""
}

# 运行主函数
main
