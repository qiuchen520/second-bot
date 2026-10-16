# <div align="center">

# QBot

**在 Android 手机上跑 QQ 机器人，一条命令搞定。**

`Termux` → `Debian (proot)` → `LinuxQQ + NapCat` → `手机图形面板`

![platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-3fb950)
![core](https://img.shields.io/badge/core-NapCat-58a6ff)
![version](https://img.shields.io/badge/version-0.1.0-blue)
![license](https://img.shields.io/badge/license-MIT-lightgrey)

</div>

---

## 🤔 这是什么

QBot 把 **QQ 机器人** 塞进 Android 手机。

它不自己实现 QQ 协议，而是用官方的 **NapCat**（基于 NTQQ 客户端）跑在 proot 容器里，
再套一层 **手机图形面板**，让你不用碰命令行。

> 相比 icqq / 第三方协议，NapCat 走的是官方客户端，**风控友好得多**。

## ✨ 特性

| 特性 | 说明 |
|---|---|
| 🚀 **一键部署** | 一条命令，从零到能登录 |
| 📱 **图形面板** | 手机浏览器操作：启停 / 日志 / 二维码 / 状态 |
| 📷 **二维码存相册** | 解决「同一个手机扫不了自己屏幕」的世纪难题 |
| 💿 **QQ 可离线装** | 支持本地 `.deb`，网络差也能装 |
| 🧩 **完整 OneBot v11** | 可对接 NoneBot / AstrBot / mioki 等框架 |
| 📦 **不污染系统** | 全部装在 proot 容器，卸载 = 删一个目录 |

## 📋 环境要求

- Android 手机，**arm64** 架构（arm32 不支持，官方无包）
- 内存建议 **3GB+**（QQ + NapCat 比较吃内存）
- 存储 **2GB+** 空闲
- 已安装 [Termux](https://github.com/termux/termux-app/releases)（优先 `arm64-v8a`，**不要用 Google Play 版**）

## 🚀 快速开始

### 1. 安装

```bash
pkg install -y curl
curl -fsSL -o install.sh https://cdn.jsdelivr.net/gh/qiuchen520/second-bot@main/install.sh
bash install.sh
```

网络不通就用这条（GitHub 加速）：

```bash
curl -fL -o install.sh https://ghproxy.net/https://raw.githubusercontent.com/qiuchen520/second-bot/main/install.sh && bash install.sh
```

### 2. 可选：用本地 QQ 安装包（推荐，快很多）

```bash
# arm64 手机用这个
curl -fL -o QQ.deb https://qqdl.gtimg.cn/qqfile/QQNT/9.9.36/beta/9ee04bef/linuxqq_3.2.34-53644_arm64.deb
bash install.sh --qq-deb ./QQ.deb
```

> 也可以把 `QQ.deb` 直接放到当前目录，脚本会自动发现。

### 3. 启动 + 登录

```bash
qbot start      # 启动机器人
qbot qr         # 把二维码保存到 /sdcard/Download/qrcode.png
```

然后用**手机 QQ**：`扫一扫` → 右上角 `相册` → 选择那张二维码 → 确认登录 ✨

### 4. 打开面板

```bash
qbot panel
```

浏览器访问 `http://127.0.0.1:8090`

## 🎛 命令速查

| 命令 | 作用 |
|---|---|
| `qbot start` | 后台启动机器人 |
| `qbot stop` | 停止机器人 |
| `qbot log` | 实时查看日志 |
| `qbot qr` | 保存登录二维码到相册 |
| `qbot panel` | 启动图形面板 |
| `qbot shell` | 进入容器内部 |
| `qbot config` | 显示配置路径与端口 |
| `qbot status` | 查看运行状态 |

## 📁 关键路径

| 内容 | 路径 |
|---|---|
| NapCat 配置 | 容器内 `/root/Napcat/opt/QQ/resources/app/app_launcher/napcat/config/` |
| NapCat WebUI | 容器内 `http://127.0.0.1:6099`（默认 token `napcat`） |
| OneBot 端口 | 默认 WS `3001` / HTTP `3000` |
| 运行日志 | `~/.qbot/napcat.log` |
| 面板文件 | `~/.qbot/server.js` |

## 🧩 生态搭配

QBot 只管「把 NapCat 跑起来 + 管好它」。机器人逻辑可以交给任何 OneBot v11 框架：

- [mioki](https://github.com/vikiboss/mioki) —— KiviBot 精神继任者，TS 编写
- [NoneBot2](https://github.com/nonebot/nonebot2) —— Python 生态最全
- [AstrBot](https://github.com/AstrBotDevs/AstrBot) —— 带 LLM 的 Bot 框架

> 架构：`NapCat（QBot 负责）` → `OneBot v11` → `你的机器人框架`

## ❓ 常见问题

<details>
<summary><b>登录失败 / 提示风控怎么办？</b></summary>

1. 换网络（WiFi ↔ 移动数据）后重试
2. 等 1~3 小时冷却
3. 换账号（新号、小号更容易过）
4. 建议用常用设备登录过的账号

</details>

<details>
<summary><b>内存不够 / 被系统杀后台？</b></summary>

- 系统设置里给 Termux **关闭省电优化**、允许后台运行
- 执行 `termux-wake-lock` 保持唤醒
- 不登录时用 `qbot stop` 释放内存

</details>

<details>
<summary><b>怎么彻底卸载？</b></summary>

```bash
qbot stop
proot-distro remove napcat   # 删容器（含 QQ 和 NapCat）
rm -rf ~/.qbot               # 删面板和日志
rm -f $PREFIX/bin/qbot       # 删命令
```

</details>

## ⚠️ 免责声明

本项目仅用于学习与技术研究，使用过程中的一切后果由使用者承担。
QQ 是腾讯公司的商标，本项目与腾讯无任何关联。

## 🙏 致谢

- [NapCat](https://github.com/NapNeko/NapCatQQ) —— 核心协议端
- [NapCat-Installer](https://github.com/NapNeko/NapCat-Installer) —— 安装脚本参考
- [proot-distro](https://github.com/termux/proot-distro) —— 容器方案
- [Termux](https://github.com/termux/termux-app) —— Android 上的 Linux

## 📄 License

MIT
