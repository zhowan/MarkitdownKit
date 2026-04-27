# MarkItDown Kit

[English](./README.md) | [中文](./README.zh-CN.md)

MarkItDown Kit 是一个轻量的 macOS 本地小工具，用来基于 [Microsoft MarkItDown](https://github.com/microsoft/markitdown) 把常见文件转换成 Markdown。

界面使用 SwiftUI 开发，底层直接调用你本机全局安装的 `markitdown` 命令。这样 `.app` 体积会非常小，同时仍然保留拖拽和批量转换的桌面体验。

## 功能特性

- 原生 macOS SwiftUI 界面
- 支持把文件直接拖进窗口
- 支持批量转换
- 默认输出到源文件所在目录
- 也可以切换成统一输出目录
- `.app` 包体积很小
- 内置转换日志

## 运行要求

- macOS
- Xcode 或 Xcode Command Line Tools
- `pipx`
- 通过 `pipx` 全局安装好的 `markitdown`

## 安装 `pipx`

如果你还没有安装 `pipx`：

```bash
brew install pipx
pipx ensurepath
```

然后重启终端，或者执行：

```bash
source ~/.zshrc
```

## 安装 MarkItDown

推荐的完整办公格式安装方式：

```bash
pipx install --force "markitdown[pdf,docx,pptx,xlsx,xls]>=0.1.5,<0.2"
```

如果你不需要 Excel，也可以用更轻的版本：

```bash
pipx install --force "markitdown[pdf,docx,pptx]>=0.1.5,<0.2"
```

## 验证环境

执行：

```bash
~/.local/bin/markitdown --help
```

如果能正常看到帮助信息，说明 app 已经能找到 `markitdown`。

如果终端里找不到 `markitdown`，把下面这行加入 `~/.zshrc`：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

然后重新加载：

```bash
source ~/.zshrc
```

## 启动方式

### 方式 1：双击启动

直接双击 [start.command](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/start.command)。

它会自动编译并启动 app。

### 方式 2：终端启动

```bash
cd /Users/wong/CodeHub/WongsCodesx/MarkitdownKit
swift run MarkitdownKitMac
```

## 打包成 app

运行下面的命令可以生成 `.app`：

```bash
cd /Users/wong/CodeHub/WongsCodesx/MarkitdownKit
./scripts/package_app.sh
```

生成后的文件在这里：

[MarkitdownKitMac.app](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/MarkitdownKitMac.app)

## 发布模式说明

这个 app 不内嵌 Python，也不内嵌 MarkItDown。

这意味着：

- app 会非常小
- 目标机器必须预先装好 `markitdown`
- 最简单的安装方式就是 `pipx`

## 支持的文件类型

最终支持哪些格式，取决于你安装 `markitdown` 时使用了哪些 extras。

推荐覆盖这些格式：

- PDF
- Word `.docx`
- PowerPoint `.pptx`
- Excel `.xlsx` 和 `.xls`
- HTML
- CSV、JSON、XML 以及其他文本类格式

## 常用命令

升级 MarkItDown：

```bash
pipx upgrade markitdown
```

重装 MarkItDown：

```bash
pipx install --force "markitdown[pdf,docx,pptx,xlsx,xls]>=0.1.5,<0.2"
```

查看 `markitdown` 实际路径：

```bash
command -v markitdown
```

## 项目结构

- [Package.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/Package.swift)：Swift 包配置
- [Sources/MarkitdownKitMac/MarkitdownKitMacApp.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/Sources/MarkitdownKitMac/MarkitdownKitMacApp.swift)：界面和转换调用逻辑
- [scripts/package_app.sh](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/scripts/package_app.sh)：`.app` 打包脚本
- [scripts/render_icon.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/scripts/render_icon.swift)：图标生成脚本
- [start.command](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/start.command)：双击启动脚本

## 备注

如果以后你想改回“完全独立、不依赖本机 `markitdown`”的版本，也可以做，但那样 app 体积会明显增大，因为需要把 Python 和整套依赖一起打进去。
