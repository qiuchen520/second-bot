#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
#  第二个 (Second Bot) — Android / Termux 一键部署脚本
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
WITH_PANEL=1

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'
info(){ printf "${C} ▸ ${N}%s\n" "$*"; }
ok(){   printf "${G} ✔ ${N}%s\n" "$*"; }
warn(){ printf "${Y} ! ${N}%s\n" "$*"; }
die(){  printf "${R} ✘ %s${N}\n" "$*"; exit 1; }

usage() {
  cat <<'EOF'
第二个 · 一键部署脚本

用法: bash install.sh [选项]

  --no-cn            容器内不使用国内 apt 镜像（默认使用清华源）
  --alias <名字>     proot 容器别名（默认 napcat）
  --resume           容器已存在时跳过创建，仅重装 NapCat
  --gh-proxy <URL>   下载加速前缀，例如 https://ghproxy.net
  --no-panel         不安装图形面板
  -h, --help         显示本帮助
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
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

printf "\n${B}第二个${N} · QQ Bot on Android   架构: ${Y}%s${N}\n\n" "$ARCH"

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

if proot-distro login "$ALIAS" -- bash -c "export CN='$USE_CN' GHPROXY='$GHPROXY'; bash -s" <<'INNER'
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

echo "   · 执行安装（下载 LinuxQQ + NapCat，需要几分钟）"
bash /tmp/napcat-installer.sh --docker n --cli n --github-proxy "${GHPROXY:-0}"
apt-get clean
INNER
then
  ok "NapCat 安装完成"
else
  die "NapCat 安装失败。可重试：bash install.sh --resume"
fi

# ---------------------------------------------------------------- second 命令
info "安装 second 管理命令……"
mkdir -p "$PREFIX/bin" "$HOME/.second-bot"
if curl -fsSL --max-time 60 "$RAW/scripts/second.sh" -o "$PREFIX/bin/second" 2>/dev/null; then
  ok "second 命令已下载"
elif [ -f "./scripts/second.sh" ]; then
  cp ./scripts/second.sh "$PREFIX/bin/second"
  ok "second 命令已从本地复制"
else
  warn "second 命令下载失败，可稍后重试"
fi
if [ -f "$PREFIX/bin/second" ]; then
  sed -i "s|^ALIAS=.*|ALIAS=\"$ALIAS\"|" "$PREFIX/bin/second"
  chmod +x "$PREFIX/bin/second"
fi

# ---------------------------------------------------------------- 图形面板
if [ "$WITH_PANEL" = 1 ]; then
  info "安装图形面板……"
  pkg install -y nodejs || warn "Node.js 安装失败，面板将不可用"

  if curl -fsSL --max-time 60 "$RAW/panel/server.js" -o "$HOME/.second-bot/server.js" 2>/dev/null; then
    ok "面板已下载"
  elif [ -f "./panel/server.js" ]; then
    cp ./panel/server.js "$HOME/.second-bot/server.js"
    ok "面板已从本地复制"
  else
    warn "面板下载失败，稍后可重试"
  fi
fi

# ---------------------------------------------------------------- 完成
printf "\n${G}────────────────────────────────────────────${N}\n"
cat <<EOF
 🎉 安装完成！

 启动机器人：   ${Y}second start${N}
 看日志：       ${Y}second log${N}
 保存二维码：   ${Y}second qr${N}
 打开面板：     ${Y}second panel${N}   浏览器 http://127.0.0.1:8090
 停止：         ${Y}second stop${N}

 首次登录建议：
   1. second start
   2. second qr       ← 二维码存到 /sdcard/Download/qrcode.png
   3. 手机 QQ「扫一扫 → 相册」选那张图 ✨
EOF
