# QBot（已归档）

> ⚠️ **本项目已停止开发，仓库已归档（只读）。**
>
> 原因很简单：社区已经有成熟方案，覆盖了本项目**全部**规划的功能，而且实现得更好。
> 与其造一个更差的轮子，不如直接推荐它。

---

## 👉 请改用这些项目

| 项目 | 说明 |
|---|---|
| **[zz6zz666/AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App)** ⭐346 | 把 **AstrBot + NapCatQQ + Ubuntu 容器**打包成一个 APK，装完即用，无需命令行 |
| [zz6zz666/Android-DIY-Sandbox](https://github.com/zz6zz666/Android-DIY-Sandbox) | 作者的新一代沙箱 App（现在的主力项目） |
| [zz6zz666/AstrBot-android-lua](https://github.com/zz6zz666/AstrBot-android-lua) | 配套的 AstrBot 皮肤包（在 Sandbox 里载入 zip） |
| [fii6/astrbot_termux](https://github.com/fii6/astrbot_termux) | 如果你喜欢 Termux 命令行方案 |

---

## 📦 这里留下了什么

虽然项目停了，但里面几个文件单独拿出来仍能用，欢迎自取：

| 文件 | 说明 |
|---|---|
| `install.sh` | Termux 一键部署 NapCat：proot 容器 + 清华源 + 支持本地 QQ 安装包 |
| `scripts/qbot.sh` | Termux 下的命令行工具：启停 / 日志 / 二维码存相册 / 进容器 |
| `panel/server.js` | 手机 Web 控制面板（深色 UI，含「二维码存相册」功能） |
| `android/` | 原生 APK 骨架 + GitHub Actions 云编译流水线（可直接作为模板） |

### 其中比较有意思的一个点：二维码存相册

同一个手机没法扫自己屏幕上的二维码。这里的做法是：

```
检测容器内 NapCat 的 qrcode.png
  → 复制到 /sdcard/Download/qrcode.png
  → 手机 QQ「扫一扫 → 相册」选图 → 同机登录 ✅
```

---

## 🧠 技术路线（供参考）

```
Termux / APK
  └─ proot ──▶ Debian / Ubuntu 容器
       ├── LinuxQQ + NapCat      → OneBot v11 (:3001)
       └── AstrBot (Python 3.12) → WebUI (:6185)
```

APK 方案的关键点：**不要把 QQ 安装包放进仓库**（法律风险），
而是 App 启动后多源测速下载；同时需要把 **静态 proot 二进制**打包进 APK。

---

## 🙏 致谢

- [AstrBot](https://github.com/AstrBotDevs/AstrBot) · [NapCat](https://github.com/NapNeko/NapCatQQ) · [NapCat-Installer](https://github.com/NapNeko/NapCat-Installer) · [Termux](https://github.com/termux/termux-app) · [proot-distro](https://github.com/termux/proot-distro)

## 📄 License

MIT
