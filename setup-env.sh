#!/bin/bash

################################################################################
# Linux开发环境一键配置工具
# 功能：自动安装oh-my-zsh、git、tmux、neovim、docker、编程语言环境等
# 支持：Ubuntu/Debian, CentOS/RHEL, Arch Linux
# 特性：幂等性、组件独立、错误隔离
################################################################################

set +e  # 不在错误时退出，由各函数处理自己的错误

################################################################################
# 全局变量和颜色定义
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计安装结果
declare -gA install_results
install_results[total]=0
install_results[success]=0
install_results[failed]=0
install_results[skipped]=0

################################################################################
# 日志函数
################################################################################

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

################################################################################
# 安装前检查
################################################################################

check_sudo() {
    if ! sudo -v &> /dev/null; then
        log_error "需要sudo权限来安装系统包，请配置sudo或以root用户运行"
        return 1
    fi
    log_info "sudo权限检查通过"
    return 0
}

check_network() {
    local test_urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://api.github.com"
    )

    for url in "${test_urls[@]}"; do
        if curl -s --head "$url" | head -n 1 | grep "HTTP" &> /dev/null; then
            log_info "网络连接检查通过 ($url)"
            return 0
        fi
    done

    log_error "无法连接到GitHub，请检查网络或配置代理"
    log_warn "脚本将继续运行，但部分功能可能失败"
    return 1
}

check_disk_space() {
    local available=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available" -lt 5 ]; then
        log_error "磁盘空间不足（至少需要5GB，当前可用: ${available}GB）"
        return 1
    fi
    log_info "磁盘空间检查通过（可用: ${available}GB）"
    return 0
}

check_required_commands() {
    local required=("bash" "curl" "grep" "awk")
    local missing=()

    for cmd in "${required[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少必要命令: ${missing[*]}"
        return 1
    fi

    log_info "必要命令检查通过"
    return 0
}

pre_check() {
    log_info "开始安装前检查..."

    local checks=(
        "check_required_commands"
        "check_disk_space"
        "check_sudo"
        "check_network"
    )

    local failed=0
    for check in "${checks[@]}"; do
        if ! $check; then
            ((failed++))
        fi
    done

    if [ $failed -gt 0 ]; then
        log_warn "$failed 项检查未通过，但继续执行..."
    else
        log_info "所有检查通过！"
    fi

    return 0
}

################################################################################
# 系统检测与包管理器
################################################################################

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

get_package_manager() {
    case $1 in
        ubuntu|debian) echo "apt" ;;
        centos|rhel|fedora) echo "dnf" ;;
        arch|manjaro) echo "pacman" ;;
        *) echo "unknown" ;;
    esac
}

################################################################################
# 包管理器封装函数
################################################################################

install_package() {
    local pkg_manager=$1
    shift
    local packages=$@

    case $pkg_manager in
        apt)
            sudo apt update && sudo apt install -y $packages
            ;;
        dnf)
            sudo dnf install -y $packages
            ;;
        pacman)
            sudo pacman -S --noconfirm $packages
            ;;
        *)
            log_error "不支持的包管理器: $pkg_manager"
            return 1
            ;;
    esac
}

################################################################################
# 基础工具安装
################################################################################

install_basic_tools() {
    local pkg_manager=$1

    log_info "正在安装基础开发工具..."

    case $pkg_manager in
        apt)
            install_package $pkg_manager git curl wget tmux build-essential \
                python3 python3-pip python3-venv ripgrep fd-find unzip
            ;;
        dnf)
            install_package $pkg_manager git curl wget tmux @development-tools \
                python3 python3-pip python3-devel ripgrep fd-find unzip
            ;;
        pacman)
            install_package $pkg_manager git curl wget tmux base-devel \
                python3 python-pip ripgrep fd unzip
            ;;
        *)
            log_error "不支持的包管理器: $pkg_manager"
            return 1
            ;;
    esac

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_info "基础工具安装成功"
        return 0
    else
        log_error "基础工具安装失败"
        return 1
    fi
}

################################################################################
# Python3相关工具安装
################################################################################

install_python_tools() {
    if command -v python3 &> /dev/null; then
        log_info "Python3已安装: $(python3 --version)"

        # 优先使用系统包管理器安装Python工具（避免externally-managed-environment错误）
        local pkg_manager=$1
        local packages_to_install=""

        case $pkg_manager in
            apt)
                # Debian/Ubuntu使用系统包
                local system_packages=(python3-black python3-flake8 python3-pylint)
                for pkg in "${system_packages[@]}"; do
                    if ! dpkg -l | grep -q "^ii  $pkg"; then
                        packages_to_install="$packages_to_install $pkg"
                    fi
                done

                if [ -n "$packages_to_install" ]; then
                    log_info "使用系统包管理器安装Python工具: $packages_to_install"
                    install_package $pkg_manager $packages_to_install || log_warn "系统包安装失败"
                fi
                ;;
            dnf)
                # CentOS/RHEL/Fedora
                local system_packages=(python3-black python3-flake8 python3-pylint)
                for pkg in "${system_packages[@]}"; do
                    if ! rpm -q "$pkg" &> /dev/null; then
                        packages_to_install="$packages_to_install $pkg"
                    fi
                done

                if [ -n "$packages_to_install" ]; then
                    log_info "使用系统包管理器安装Python工具: $packages_to_install"
                    install_package $pkg_manager $packages_to_install || log_warn "系统包安装失败"
                fi
                ;;
            pacman)
                # Arch Linux
                local system_packages=(python-black python-flake8 python-pylint)
                for pkg in "${system_packages[@]}"; do
                    if ! pacman -Q "$pkg" &> /dev/null; then
                        packages_to_install="$packages_to_install $pkg"
                    fi
                done

                if [ -n "$packages_to_install" ]; then
                    log_info "使用系统包管理器安装Python工具: $packages_to_install"
                    install_package $pkg_manager $packages_to_install || log_warn "系统包安装失败"
                fi
                ;;
        esac

        # 验证安装
        local tools=("black" "flake8" "pylint")
        for tool in "${tools[@]}"; do
            if command -v $tool &> /dev/null || python3 -m "$tool" --version &> /dev/null; then
                log_info "Python工具 $tool 可用"
            else
                log_warn "Python工具 $tool 未找到（可能包名不同或未安装）"
            fi
        done

        return 0
    else
        log_error "Python3未安装"
        return 1
    fi
}

################################################################################
# Go安装
################################################################################

install_go() {
    if command -v go &> /dev/null; then
        log_info "Go已安装: $(go version)"
        return 0
    fi

    log_info "正在安装Go..."
    local go_version="1.23.5"
    local go_arch="amd64"

    # 检测架构
    [ "$(uname -m)" = "aarch64" ] && go_arch="arm64"

    local go_file="go${go_version}.linux-${go_arch}.tar.gz"

    # 下载并安装
    cd /tmp
    if ! wget -q "https://go.dev/dl/${go_file}"; then
        log_error "Go下载失败"
        return 1
    fi

    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$go_file"
    rm -f "$go_file"

    # 设置PATH
    if ! grep -q '/usr/local/go/bin' ~/.bashrc 2>/dev/null; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    if ! grep -q '/usr/local/go/bin' ~/.zshrc 2>/dev/null; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    fi

    export PATH=$PATH:/usr/local/go/bin

    if command -v go &> /dev/null; then
        log_info "Go安装成功: $(go version)"
        return 0
    else
        log_error "Go安装后验证失败"
        return 1
    fi
}

################################################################################
# Rust安装
################################################################################

install_rust() {
    if command -v rustc &> /dev/null; then
        log_info "Rust已安装: $(rustc --version)"
        return 0
    fi

    log_info "正在安装Rust..."
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        log_error "Rust安装失败"
        return 1
    fi

    # 加载rust环境
    source ~/.cargo/env

    if command -v rustc &> /dev/null; then
        log_info "Rust安装成功: $(rustc --version)"
        return 0
    else
        log_error "Rust安装后验证失败"
        return 1
    fi
}

################################################################################
# Docker安装
################################################################################

install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker已安装: $(docker --version)"
        return 0
    fi

    log_info "正在安装Docker..."
    local pkg_manager=$1

    case $pkg_manager in
        apt)
            # 安装依赖
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release

            # 添加Docker官方GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            # 添加Docker仓库
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # 安装Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        dnf)
            # CentOS/RHEL
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        pacman)
            # Arch Linux
            sudo pacman -S --noconfirm docker docker-compose
            ;;
        *)
            log_error "不支持的包管理器: $pkg_manager"
            return 1
            ;;
    esac

    # 启动Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker

    # 将当前用户添加到docker组（可选）
    if ! groups | grep -q docker; then
        log_warn "将当前用户添加到docker组（需要重新登录生效）"
        sudo usermod -aG docker $USER
    fi

    # 验证安装
    if command -v docker &> /dev/null; then
        log_info "Docker安装成功: $(docker --version)"
        return 0
    else
        log_error "Docker安装后验证失败"
        return 1
    fi
}

################################################################################
# fnm和Node.js安装
################################################################################

install_fnm() {
    if command -v fnm &> /dev/null; then
        log_info "fnm已安装: $(fnm --version)"
        return 0
    fi

    log_info "正在安装fnm..."

    # 下载并安装fnm
    if ! curl -fsSL https://fnm.vercel.app/install | bash; then
        log_error "fnm安装失败"
        return 1
    fi

    # 加载fnm环境
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env --shell bash)"

    # 安装最新的LTS Node.js版本
    if command -v fnm &> /dev/null; then
        log_info "fnm安装成功，正在安装Node.js LTS..."
        fnm install --lts
        fnm use lts/*

        # 设置PATH
        if ! grep -q 'fnm env' ~/.bashrc 2>/dev/null; then
            echo 'eval "$(fnm env --shell bash)"' >> ~/.bashrc
        fi
        if ! grep -q 'fnm env' ~/.zshrc 2>/dev/null; then
            echo 'eval "$(fnm env --shell zsh)"' >> ~/.zshrc
        fi

        log_info "Node.js安装成功: $(node --version)"
        log_info "npm安装成功: $(npm --version)"
        return 0
    else
        log_error "fnm安装后验证失败"
        return 1
    fi
}

################################################################################
# Oh-my-zsh安装和配置
################################################################################

install_oh_my_zsh() {
    # 安装oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "正在安装oh-my-zsh..."
        if ! sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_error "oh-my-zsh安装失败"
            return 1
        fi
    else
        log_info "oh-my-zsh已安装"
    fi

    # 安装插件
    local zsh_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"

    # zsh-autosuggestions
    if [ ! -d "$zsh_plugins_dir/zsh-autosuggestions" ]; then
        log_info "安装zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_plugins_dir/zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions已安装"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$zsh_plugins_dir/zsh-syntax-highlighting" ]; then
        log_info "安装zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_plugins_dir/zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting已安装"
    fi

    # zsh-z
    if [ ! -d "$zsh_plugins_dir/zsh-z" ]; then
        log_info "安装zsh-z..."
        git clone https://github.com/agkozak/zsh-z "$zsh_plugins_dir/zsh-z"
    else
        log_info "zsh-z已安装"
    fi

    # 配置.zshrc
    configure_zshrc

    log_info "oh-my-zsh配置完成"
    return 0
}

configure_zshrc() {
    # 备份.zshrc
    if [ ! -f "$HOME/.zshrc.backup" ]; then
        cp ~/.zshrc ~/.zshrc.backup
    fi

    # 更新插件列表
    if grep -q "^plugins=(git)" ~/.zshrc; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)/' ~/.zshrc
        log_info "已更新.zshrc插件配置"
    else
        log_warn "无法自动更新.zshrc插件配置，请手动添加："
        log_warn "plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)"
    fi
}

################################################################################
# Tmux配置
################################################################################

setup_tmux() {
    # 检查tmux是否已安装
    if ! command -v tmux &> /dev/null; then
        log_error "tmux未安装，跳过配置"
        return 1
    fi

    # 备份现有配置
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
        log_info "已备份现有tmux配置"
    fi

    # 复制预设的tmux配置文件
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$script_dir/configs/tmux.conf" ]; then
        cp "$script_dir/configs/tmux.conf" "$HOME/.tmux.conf"
        log_info "tmux配置已安装"
        return 0
    else
        log_warn "预设的tmux配置文件不存在，创建默认配置"
        create_default_tmux_config
        return 0
    fi
}

create_default_tmux_config() {
    cat > ~/.tmux.conf << 'EOF'
# 设置prefix为Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# 启用鼠标
set -g mouse on

# 设置窗口和面板索引从1开始
set -g base-index 1
setw -g pane-base-index 1

# 重新加载配置
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# 垂直和水平分割窗口
bind | split-window -h
bind - split-window -v

# 更新面板分隔符样式
set -g pane-border-style 'fg=colour235,bg=black'
set -g pane-active-border-style 'fg=colour51,bg=black'

# 状态栏配置
set -g status-style 'fg=colour15,bg=colour233'
set -g status-left-length 100
set -g status-right-length 100
set -g status-left '[#S] '
set -g status-right '%H:%M %Y-%m-%d'
EOF
    log_info "默认tmux配置已创建"
}

################################################################################
# Neovim安装
################################################################################

install_neovim() {
    local pkg_manager=$1

    if command -v nvim &> /dev/null; then
        log_info "Neovim已安装: $(nvim --version | head -n1)"
        return 0
    fi

    log_info "正在安装Neovim..."

    case $pkg_manager in
        apt)
            # 添加Neovim PPA
            sudo add-apt-repository ppa:neovim-ppa/unstable -y
            sudo apt update
            sudo apt install -y neovim
            ;;
        dnf)
            sudo dnf install -y neovim
            ;;
        pacman)
            sudo pacman -S --noconfirm neovim
            ;;
        *)
            log_error "不支持的包管理器: $pkg_manager"
            return 1
            ;;
    esac

    if command -v nvim &> /dev/null; then
        log_info "Neovim安装成功: $(nvim --version | head -n1)"
        return 0
    else
        log_error "Neovim安装失败"
        return 1
    fi
}

################################################################################
# Neovim配置
################################################################################

setup_nvim_config() {
    # 备份现有配置
    if [ -d "$HOME/.config/nvim" ]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        log_info "已备份现有nvim配置"
    fi

    # 复制当前目录的nvim配置
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ ! -d "$script_dir/nvim" ]; then
        log_error "nvim配置目录不存在: $script_dir/nvim"
        return 1
    fi

    cp -r "$script_dir/nvim" "$HOME/.config/nvim"
    log_info "nvim配置已复制"

    # 首次运行nvim以安装插件
    log_info "正在安装nvim插件（可能需要几分钟）..."
    nvim --headless "+Lazy! sync" +qa --silent >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_info "nvim插件安装成功"
    else
        log_warn "nvim插件安装可能有问题，请手动检查: nvim"
    fi

    # 安装LSP服务器
    log_info "正在安装LSP服务器（可能需要几分钟）..."
    nvim --headless "+Mason" +qa --silent >/dev/null 2>&1
    nvim --headless "+MasonInstall pylsp pyright lua-ls rust-analyzer gopls clangd" +qa --silent >/dev/null 2>&1

    log_info "LSP服务器安装完成"
    return 0
}

################################################################################
# 执行安装步骤（带错误处理）
################################################################################

run_install_step() {
    local step_name=$1
    local step_function=$2
    shift 2
    local args=$@

    ((install_results[total]++))
    log_step "[$step_name] 开始..."

    if $step_function $args; then
        log_info "[$step_name] 成功"
        ((install_results[success]++))
        install_results[$step_name]="success"
        return 0
    else
        log_warn "[$step_name] 失败，但继续执行其他步骤"
        ((install_results[failed]++))
        install_results[$step_name]="failed"
        return 1
    fi
}

################################################################################
# 主流程
################################################################################

main() {
    log_info "=========================================="
    log_info "  Linux开发环境一键配置工具"
    log_info "=========================================="

    # 安装前检查
    log_info ""
    log_step "Step 0: 安装前检查"
    run_install_step "预检查" "pre_check"

    # 检测系统
    log_info ""
    log_step "Step 1: 系统检测"
    distro=$(detect_distro)
    log_info "检测到系统: $distro"

    pkg_manager=$(get_package_manager $distro)
    if [ "$pkg_manager" = "unknown" ]; then
        log_error "不支持的系统，退出"
        exit 1
    fi
    log_info "使用包管理器: $pkg_manager"

    # 安装基础工具
    log_info ""
    log_step "Step 2: 安装基础开发工具"
    run_install_step "基础工具" "install_basic_tools" $pkg_manager

    # 安装语言环境
    log_info ""
    log_step "Step 3: 安装编程语言环境"
    run_install_step "Python工具" "install_python_tools" $pkg_manager
    run_install_step "Go" "install_go"
    run_install_step "Rust" "install_rust"

    # 安装Docker
    log_info ""
    log_step "Step 3.5: 安装Docker"
    run_install_step "Docker" "install_docker" $pkg_manager

    # 安装Node.js（通过fnm）
    log_info ""
    log_step "Step 3.6: 安装Node.js（通过fnm）"
    run_install_step "fnm和Node.js" "install_fnm"

    # 安装oh-my-zsh
    log_info ""
    log_step "Step 4: 安装和配置oh-my-zsh"
    run_install_step "oh-my-zsh" "install_oh_my_zsh"

    # 安装tmux
    log_info ""
    log_step "Step 5: 安装和配置tmux"
    run_install_step "tmux安装" "install_package" $pkg_manager tmux
    if command -v tmux &> /dev/null; then
        run_install_step "tmux配置" "setup_tmux"
    fi

    # 安装Neovim
    log_info ""
    log_step "Step 6: 安装Neovim"
    run_install_step "Neovim安装" "install_neovim" $pkg_manager

    # 配置Neovim
    if command -v nvim &> /dev/null; then
        log_info ""
        log_step "Step 7: 配置Neovim"
        run_install_step "Neovim配置" "setup_nvim_config"
    fi

    # 打印安装摘要
    log_info ""
    log_info "=========================================="
    log_info "  安装摘要"
    log_info "=========================================="
    log_info "总计步骤: ${install_results[total]}"
    log_info "成功: ${install_results[success]}"
    log_info "失败: ${install_results[failed]}"
    log_info "跳过: ${install_results[skipped]}"

    if [ ${install_results[failed]} -gt 0 ]; then
        log_warn "以下步骤失败："
        for step in "${!install_results[@]}"; do
            if [ "${install_results[$step]}" = "failed" ]; then
                log_warn "  - $step"
            fi
        done
    fi

    log_info ""
    log_info "=========================================="
    log_info "  环境配置完成！"
    log_info "=========================================="
    log_info "请重启终端或运行以下命令应用配置："
    log_info "  source ~/.zshrc     # 应用zsh配置"
    log_info "  source ~/.cargo/env # 应用Rust环境"
    log_info "  eval \"\$(fnm env --shell bash)\" # 应用fnm环境"
    log_info ""
    log_info "快速验证安装："
    log_info "  nvim --version      # 检查Neovim"
    log_info "  tmux -V             # 检查tmux"
    log_info "  python3 --version   # 检查Python"
    log_info "  go version          # 检查Go"
    log_info "  rustc --version     # 检查Rust"
    log_info "  node --version      # 检查Node.js"
    log_info "  docker --version    # 检查Docker"
}

# 执行主函数
main "$@"
