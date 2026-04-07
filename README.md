# Alacritty 配置

这是我的 Alacritty 终端模拟器配置，集成了 zsh + tmux 的工作流程。
当前 tmux 前缀为 `Ctrl+A`，并通过 `Cmd` 快捷键桥接常用窗口操作。

## 功能特性

### 🎨 主题支持

- 支持多种主题切换：Rose Pine、Catppuccin 系列
- 当前使用：Rose Pine 主题
- 透明窗口装饰效果

### ⌨️ 快捷键绑定

#### 基础操作

- `Cmd+R`: 清屏
- `Cmd+Shift+W`: 退出 Alacritty
- `Cmd+N`: 新建实例
- `Cmd+T`: 创建新的 tmux 窗口
- `Cmd+W`: 关闭当前 tmux 窗口

#### 文本导航

- `Alt+←/→`: 按单词移动光标
- `Cmd+←/→`: 移动到行首/行尾
- `Cmd+Backspace`: 删除到行首
- `Alt+Backspace`: 删除单词

#### Tmux 窗口管理

- `Cmd+[`: 切换到上一个 tmux 窗口
- `Cmd+]`: 切换到下一个 tmux 窗口
- `Cmd+1-9`: 直接切换到对应编号的 tmux 窗口

### 🛠️ 配置详情

#### 字体设置

- 字体：FiraCode Nerd Font Mono
- 大小：17pt
- 支持 Nerd Font 图标和连字

#### 窗口设置

- 尺寸：106 列 × 25 行
- 内边距：水平 20px，垂直 22px
- 透明窗口装饰
- 窗口透明度：0.94
- 动态内边距：开启
- macOS 模糊背景：开启

#### 滚动设置

- 历史记录：100,000 行
- 滚动倍数：4

#### 自动启动 Tmux

- 启动时自动连接或创建固定会话 `main`
- 命令：`tmux new-session -A -s main`

## 文件结构

```
~/.config/alacritty/
├── alacritty.toml              # 主配置文件
├── rose-pine.toml              # Rose Pine 主题 (当前)
├── rose-pine-dawn.toml         # Rose Pine Dawn 变体
├── rose-pine-moon.toml         # Rose Pine Moon 变体
├── catppuccin-latte.toml       # Catppuccin Latte 主题
├── catppuccin-frappe.toml      # Catppuccin Frappe 主题
├── catppuccin-macchiato.toml   # Catppuccin Macchiato 主题
├── catppuccin-mocha.toml       # Catppuccin Mocha 主题
└── README.md                   # 本文件
```

## 使用说明

### 切换主题

编辑 `alacritty.toml` 文件中的 `import` 部分，注释掉当前主题，取消注释想要的主题：

```toml
[general]
import = [
  # "~/.config/alacritty/rose-pine.toml"
  "~/.config/alacritty/catppuccin-mocha.toml"  # 切换到 Catppuccin Mocha
]
```

### Tmux 工作流程

1. 打开 Alacritty 自动进入 tmux 会话
2. 使用 `Cmd+T` 创建新窗口
3. 使用 `Cmd+1-9` 或 `Cmd+[/]` 切换窗口
4. 使用 `Cmd+W` 关闭窗口

### 自定义配置

- 修改字体大小：调整 `[font] size` 值
- 修改窗口尺寸：调整 `[window.dimensions]` 值
- 添加新的快捷键：在 `[[keyboard.bindings]]` 部分添加

## 依赖要求

- Alacritty 终端模拟器
- Tmux 会话管理器
- FiraCode Nerd Font 字体
- Zsh shell

## Zsh 优化配置

仓库已提供 zsh 优化片段：[zsh-alacritty-tmux.zsh](zsh-alacritty-tmux.zsh)。

在 `~/.zshrc` 末尾添加：

```zsh
source ~/.config/alacritty/zsh-alacritty-tmux.zsh
```

该片段包含：

- 历史记录去重与共享策略（更适合多 tmux pane）
- 补全菜单与大小写匹配优化
- 与 Alacritty 键位一致的单词跳转/删除绑定
- tmux 常用别名
- 与 Oh My Zsh / Powerlevel10k 兼容（不覆盖现有主题提示）
- 固定策略配置（不使用 fallback 分支）

快速验证：

```bash
source ~/.zshrc
bindkey | grep -E '\\^\\[b|\\^\\[f|\\^\\[\\^\\?'
echo $EDITOR
```

一键应用（幂等，可重复执行）：

```bash
zsh ~/.config/alacritty/apply-zsh-optimizations.zsh
```

可指定目标文件：

```bash
zsh ~/.config/alacritty/apply-zsh-optimizations.zsh ~/.zshrc
```

## 安装指南

1. 安装依赖：

   ```bash
   # macOS (使用 Homebrew)
   brew install alacritty tmux
   brew tap homebrew/cask-fonts
   brew install font-fira-code-nerd-font

   # 或者手动下载 FiraCode Nerd Font
   ```

2. 复制配置文件到正确位置：

   ```bash
   cp -r . ~/.config/alacritty/
   ```

3. 重启 Alacritty 或重新加载配置 (支持热重载)

## Tmux 键位说明

本配置将常用的 tmux 操作映射到 macOS 风格的快捷键：
tmux 前缀：`Ctrl+A`

| 快捷键    | Tmux 命令    | 功能           |
| --------- | ------------ | -------------- |
| `Cmd+T`   | `Ctrl+A c`   | 新建窗口       |
| `Cmd+W`   | `Ctrl+A &`   | 关闭窗口       |
| `Cmd+[`   | `Ctrl+A p`   | 上一个窗口     |
| `Cmd+]`   | `Ctrl+A n`   | 下一个窗口     |
| `Cmd+1-9` | `Ctrl+A 1-9` | 切换到指定窗口 |

## 兼容约定

- tmux 前缀固定为 `Ctrl+A`，与 Alacritty 中 `Cmd+T`、`Cmd+W`、`Cmd+1-9` 等桥接快捷键一致。
- 默认 shell 使用 zsh：tmux 中的 `default-shell` 固定为 `/bin/zsh`，避免会话内 shell 漂移。
- 终端颜色策略：Alacritty 外层保持 `TERM=alacritty`，tmux 通过 `terminal-overrides` 为 `alacritty` 与 `xterm-256color` 同时启用 truecolor。

可用以下命令快速验证：

```bash
echo $TERM
tmux show -gv default-shell
tmux show -gv terminal-overrides
```

## 故障排除

### Tmux 未自动启动

- 检查 tmux 是否已安装：`which tmux`
- 确认 zsh 是默认 shell：`echo $SHELL`

### 字体显示异常

- 确认已安装 FiraCode Nerd Font
- 检查字体名称是否正确

### 主题未生效

- 确认主题文件存在于配置目录
- 检查 `import` 路径是否正确
- 重启 Alacritty 以重新加载配置

## 个性化建议

1. **根据屏幕调整字体大小**：4K 显示器建议 16-18pt，普通显示器 12-14pt
2. **根据使用习惯调整窗口尺寸**：开发推荐 120×30，日常使用 100×25
3. **选择合适的主题**：白天推荐 Rose Pine Dawn，夜晚推荐 Rose Pine 或 Catppuccin Mocha
4. **透明度微调建议**：若更重视对比度可将 `opacity` 调到 `0.97`；若更重视氛围可降到 `0.90-0.92`

---
