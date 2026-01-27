# Linux开发环境一键配置工具

一键配置完整的Linux开发环境，包括oh-my-zsh、tmux、neovim、docker及多种编程语言环境。

## 功能特性

- ✅ **自动系统检测** - 支持Ubuntu/Debian、CentOS/RHEL、Arch Linux
- ✅ **幂等性设计** - 可以多次安全运行，不会重复安装
- ✅ **组件独立** - 单个组件失败不影响其他组件
- ✅ **完整开发环境** - 包含所有常用开发工具
- ✅ **配置预设** - 包含优化的tmux和nvim配置

## 安装内容

### 语言环境
- **Python3** + 开发工具（black, flake8, pylint）
- **Go 1.23.5**
- **Rust**（通过rustup）
- **Node.js LTS**（通过fnm版本管理器）

### 开发工具
- **Git** - 版本控制
- **Tmux** - 终端复用器（带预设配置）
- **Neovim** - 现代化vim编辑器（使用项目中的nvim配置）
- **Docker** - 容器化环境（含Docker Compose）
- **ripgrep & fd** - 高效搜索工具
- **Oh-my-zsh** + 4个插件（zsh-autosuggestions、zsh-syntax-highlighting、zsh-z、git）

### Nvim生态
- 30+ 插件（lazy.nvim管理）
- 6个LSP服务器（pylsp、pyright、lua-ls、rust-analyzer、gopls、clangd）

## 快速开始

### 基本使用

```bash
# 1. 克隆或下载项目
git clone <repository-url>
cd half

# 2. 赋予执行权限（已设置）
chmod +x setup-env.sh

# 3. 运行安装脚本
./setup-env.sh
```

### 重新运行脚本

脚本支持幂等性，可以多次运行而不会产生副作用：

```bash
# 添加新组件后重新运行
./setup-env.sh
```

## 安装后配置

安装完成后，请重启终端或运行以下命令应用配置：

```bash
source ~/.zshrc     # 应用zsh配置
source ~/.cargo/env # 应用Rust环境
eval "$(fnm env --shell bash)" # 应用fnm环境
```

## 验证安装

运行以下命令验证安装是否成功：

```bash
nvim --version      # 检查Neovim
tmux -V             # 检查tmux
python3 --version   # 检查Python
go version          # 检查Go
rustc --version     # 检查Rust
node --version      # 检查Node.js
docker --version    # 检查Docker
```

## 项目结构

```
.
├── setup-env.sh           # 主安装脚本（790行）
├── configs/
│   └── tmux.conf          # Tmux配置文件（预设）
├── nvim/                  # Nvim配置目录
│   ├── init.lua
│   ├── lazy-lock.json
│   └── lua/
│       ├── config/
│       └── plugins/
└── README.md              # 本文件
```

## 注意事项

1. **权限要求**: 脚本需要sudo权限来安装系统包
2. **网络要求**: 部分下载需要稳定的网络连接（会检查GitHub连接）
3. **配置备份**: 现有配置会被自动备份（带时间戳）
4. **Docker用户组**: 安装Docker后需要重新登录才能免sudo使用
5. **磁盘空间**: 至少需要5GB可用空间

## 预期安装时间

- **Ubuntu/Debian**: 约15-20分钟
- **CentOS/RHEL**: 约20-25分钟
- **Arch Linux**: 约10-15分钟

主要耗时：
- Neovim插件安装: ~3分钟
- Rust安装: ~2分钟
- Docker安装: ~3分钟
- Node.js安装: ~2分钟
- LSP服务器安装: ~5分钟

## 故障排除

### 网络问题
如果无法连接GitHub，请配置代理：
```bash
export http_proxy=http://your-proxy:port
export https_proxy=http://your-proxy:port
./setup-env.sh
```

### 权限问题
确保当前用户有sudo权限：
```bash
sudo -v  # 验证sudo权限
```

### 部分组件失败
脚本会显示失败的组件，可以单独重新运行脚本修复：
```bash
./setup-env.sh  # 再次运行会跳过已安装的组件
```

## 支持的系统

- ✅ Ubuntu 20.04, 22.04+
- ✅ Debian 10+, 11+
- ✅ CentOS 8+, 9+
- ✅ RHEL 8+, 9+
- ✅ Arch Linux
- ✅ Manjaro

## 配置文件说明

### Tmux配置 (configs/tmux.conf)
- Prefix键: `Ctrl-a`
- 鼠标支持已启用
- 状态栏显示时间和会话名
- Vi键位绑定

### Nvim配置 (nvim/)
- 使用lazy.nvim管理插件
- Mason国内镜像加速
- 自动补全和LSP支持
- 详细的LSP配置请参考 `nvim/lua/plugins/`

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎提交Issue和Pull Request！
