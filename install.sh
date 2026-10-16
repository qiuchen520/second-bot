#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
#  QBot — Android / Termux 一键部署脚本
#  Termux  ──proot-distro──▶  Debian  ──▶  LinuxQQ + NapCat
#
#  用法: bash install.sh [选项]     （--help 查看全部选项）
#  仓库: https://github.com/qiuchen520/second-bot
# ============================================================================
set -o pipefail

REPO="qiuchen520/second-bot"
RAW="https://raw.githubusercontent.com/${REPO}/main"

ALIAS="napcat"
IMAGE="debian:bookworm-slim"
USE_CN=1
RESUME=0
GHPROXY=""
QQ_DEB=""
WITH_PANEL=1

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'
info(){ printf "${C} ▸ ${N}%s\n" "$*"; }
ok(){   printf "${G} ✔ ${N}%s\n" "$*"; }
warn(){ printf "${Y} ! ${N}%s\n" "$*"; }
die(){  printf "${R} ✘ %s${N}\n" "$*"; exit 1; }

usage() {
  cat <<'EOF'
QBot · 一键部署脚本

用法: bash install.sh [选项]

  --qq-deb <路径>    使用本地 QQ 安装包（.deb），跳过自动下载
                     也可直接把 QQ.deb 放到当前目录，脚本会自动发现
  --no-cn            容器内不使用国内 apt 镜像（默认使用清华源）
  --alias <名字>     proot 容器别名（默认 napcat）
  --resume           容器已存在时跳过创建，仅重装 NapCat
  --gh-proxy <URL>   下载加速前缀，例如 https://ghproxy.net
  --no-panel         不安装图形面板
  -h, --help         显示本帮助

QQ 安装包官方直链（arm64 手机用第一个）:
  arm64: https://qqdl.gtimg.cn/qqfile/QQNT/9.9.36/beta/9ee04bef/linuxqq_3.2.34-53644_arm64.deb
  amd64: https://qqdl.gtimg.cn/qqfile/QQNT/9.9.36/beta/9ee04bef/linuxqq_3.2.34-53644_amd64.deb
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --qq-deb)   QQ_DEB="${2:?缺少路径}"; shift 2 ;;
    --no-cn)    USE_CN=0; shift ;;
    --cn)       USE_CN=1; shift ;;
    --alias)    ALIAS="${2:?缺少别名}"; shift 2 ;;
    --resume)   RESUME=1; shift ;;
    --gh-proxy) GHPROXY="${2%/}"; shift 2 ;;
    --no-panel) WITH_PANEL=0; shift ;;
    -h|--help)  usage ;;
    *)          die "未知参数: $1（用 --help 查看用法）" ;;
  esac
done

# ---------------------------------------------------------------- 环境检查
[ -n "$PREFIX" ] || die "请在 Termux 中运行本脚本。"

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ARCH="arm64" ;;
  armv7l|armv8l|arm) die "LinuxQQ 官方未提供 32 位 ARM 安装包，请使用 arm64 设备。" ;;
  x86_64|amd64) ARCH="amd64" ;;
  *) warn "未知架构 $ARCH，可能失败。" ;;
esac

printf "\n${B}QBot${N} · QQ Bot on Android   架构: ${Y}%s${N}\n\n" "$ARCH"

# ---------------------------------------------------------------- 基础依赖
info "检查 Termux 基础依赖……"
pkg install -y proot-distro screen curl || die "基础依赖安装失败，请先执行: pkg update && pkg upgrade"
ok "proot-distro / screen / curl 就绪"

# ---------------------------------------------------------------- 存储权限
if [ ! -d "$HOME/storage/downloads" ] && command -v termux-setup-storage >/dev/null 2>&1; then
  warn "申请存储权限（用于保存二维码到相册），请在弹窗点「允许」"
  termux-setup-storage
  sleep 4
fi

# ---------------------------------------------------------------- 本地 QQ 包
if [ -z "$QQ_DEB" ]; then
  for c in "./QQ.deb" "$HOME/QQ.deb" "$HOME/Download/QQ.deb" "$PREFIX/tmp/QQ.deb"; do
    if [ -f "$c" ]; then QQ_DEB="$c"; break; fi
  done
fi
if [ -n "$QQ_DEB" ] && [ -f "$QQ_DEB" ]; then
  mkdir -p "$PREFIX/tmp"
  cp "$QQ_DEB" "$PREFIX/tmp/QQ.deb"
  ok "已准备本地 QQ 安装包: $QQ_DEB"
else
  info "未发现本地 QQ 安装包 → 将由官方安装器自动下载"
  info "（想手动下载？看本脚本 --help 里的官方直链）"
fi

# ---------------------------------------------------------------- 创建容器
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$ALIAS"

if [ -d "$ROOTFS/root" ]; then
  if [ "$RESUME" = 1 ]; then
    ok "复用已有容器：$ALIAS"
  else
    warn "容器 $ALIAS 已存在，跳过创建（想重装：proot-distro remove $ALIAS）"
  fi
else
  info "下载并创建 Debian 容器（约 150MB，1~10 分钟）……"
  proot-distro install "$IMAGE" --override-alias "$ALIAS" \
    || proot-distro install debian --override-alias "$ALIAS" \
    || proot-distro install ubuntu --override-alias "$ALIAS" \
    || die "容器创建失败。请检查网络，或手动执行: proot-distro install debian"
  ok "容器创建完成"
fi

# ---------------------------------------------------------------- 容器内安装
info "开始安装 LinuxQQ + NapCat（10~30 分钟，请保持 Termux 在前台 ☕）"

if proot-distro login --shared-tmp "$ALIAS" -- bash -c "export CN='$USE_CN' GHPROXY='$GHPROXY'; bash -s" <<'INNER'
set -e
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

if [ "$CN" = "1" ]; then
  echo "   · 切换 Debian 镜像源 → 清华 TUNA"
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do
    if [ -f "$f" ]; then
      sed -i -e 's|https\?://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' \
             -e 's|https\?://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' "$f"
    fi
  done
fi

echo "   · 更新软件包索引"
apt-get update -y -qq
apt-get install -y -qq sudo curl ca-certificates libgcrypt20 xz-utils jq unzip procps

echo "   · 下载 NapCat 官方安装器"
URL="https://raw.githubusercontent.com/NapNeko/NapCat-Installer/main/script/install.sh"
if [ -n "$GHPROXY" ]; then URL="$GHPROXY/$URL"; fi
curl -fsSL --connect-timeout 20 --max-time 1800 "$URL" -o /tmp/napcat-installer.sh
head -c 2 /tmp/napcat-installer.sh | grep -q '#!' || { echo "下载内容不是脚本"; exit 1; }

cd /tmp
if [ -f /tmp/QQ.deb ]; then
  echo "   · 检测到本地 QQ 安装包，将直接使用"
fi
echo "   · 执行安装（下载 LinuxQQ + NapCat，需要几分钟）"
bash /tmp/napcat-installer.sh --docker n --cli n --github-proxy "${GHPROXY:-0}"
apt-get clean
INNER
then
  ok "NapCat 安装完成"
else
  die "NapCat 安装失败。可重试：bash install.sh --resume"
fi

# ---------------------------------------------------------------- qbot 命令
info "安装 qbot 管理命令……"
mkdir -p "$PREFIX/bin" "$HOME/.qbot"
if curl -fsSL --max-time 60 "$RAW/scripts/qbot.sh" -o "$PREFIX/bin/qbot" 2>/dev/null; then
  ok "qbot 命令已下载"
elif [ -f "./scripts/qbot.sh" ]; then
  cp ./scripts/qbot.sh "$PREFIX/bin/qbot"
  ok "qbot 命令已从本地复制"
else
  warn "qbot 命令下载失败，可稍后重试"
fi
if [ -f "$PREFIX/bin/qbot" ]; then
  sed -i "s|^ALIAS=.*|ALIAS=\"$ALIAS\"|" "$PREFIX/bin/qbot"
  chmod +x "$PREFIX/bin/qbot"
fi

# ---------------------------------------------------------------- 图形面板
if [ "$WITH_PANEL" = 1 ]; then
  info "安装图形面板……"
  pkg install -y nodejs || warn "Node.js 安装失败，面板将不可用"

  if curl -fsSL --max-time 60 "$RAW/panel/server.js" -o "$HOME/.qbot/server.js" 2>/dev/null; then
    ok "面板已下载"
  elif [ -f "./panel/server.js" ]; then
    cp ./panel/server.js "$HOME/.qbot/server.js"
    ok "面板已从本地复制"
  else
    warn "面板下载失败，稍后可重试"
  fi
fi

# ---------------------------------------------------------------- 完成
printf "\n${G}────────────────────────────────────────────${N}\n"
cat <<EOF
 🎉 QBot 安装完成！

 启动机器人：   ${Y}qbot start${N}
 看日志：       ${Y}qbot log${N}
 保存二维码：   ${Y}qbot qr${N}
 打开面板：     ${Y}qbot panel${N}   浏览器 http://127.0.0.1:8090
 停止：         ${Y}qbot stop${N}

 首次登录建议：
   1. qbot start
   2. qbot qr       ← 二维码存到 /sdcard/Download/qrcode.png
   3. 手机 QQ「扫一扫 → 相册」选那张图 ✨
EOF
