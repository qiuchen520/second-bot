#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
#  第二个 (Second Bot) — Android / Termux 一键部署脚本
#  Termux  ──proot-distro──▶  Debian  ──▶  LinuxQQ + NapCat
#
#  用法: bash install.sh [选项]    （--help 查看全部选项）
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
info(){ printf "${C} \u25b8 ${N}%s\n" "$*"; }
ok(){   printf "${G} \u2714 ${N}%s\n" "$*"; }
warn(){ printf "${Y} ! ${N}%s\n" "$*"; }
die(){  printf "${R} \u2718 %s${N}\n" "$*"; exit 1; }

usage() {
  cat <<'EOF'
\u7b2c\u4e8c\u4e2a \u00b7 \u4e00\u952e\u90e8\u7f72\u811a\u672c

\u7528\u6cd5: bash install.sh [\u9009\u9879]

  --no-cn            \u5bb9\u5668\u5185\u4e0d\u4f7f\u7528\u56fd\u5185 apt \u955c\u50cf\uff08\u9ed8\u8ba4\u4f7f\u7528\uff09
  --alias <\u540d\u5b57>     proot \u5bb9\u5668\u522b\u540d\uff08\u9ed8\u8ba4 napcat\uff09
  --resume           \u5bb9\u5668\u5df2\u5b58\u5728\u65f6\u8df3\u8fc7\u521b\u5efa
  --gh-proxy <URL>   \u4e0b\u8f7d\u52a0\u901f\u524d\u7f00\uff0c\u4f8b\u5982 https://ghproxy.net
  --no-panel         \u4e0d\u5b89\u88c5\u56fe\u5f62\u9762\u677f
  -h, --help         \u663e\u793a\u672c\u5e2e\u52a9
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-cn)    USE_CN=0; shift ;;
    --cn)       USE_CN=1; shift ;;
    --alias)    ALIAS="${2:?\u7f3a\u5c11\u522b\u540d}"; shift 2 ;;
    --resume)   RESUME=1; shift ;;
    --gh-proxy) GHPROXY="${2%/}"; shift 2 ;;
    --no-panel) WITH_PANEL=0; shift ;;
    -h|--help)  usage ;;
    *)          die "\u672a\u77e5\u53c2\u6570: $1\uff08\u7528 --help \u67e5\u770b\u7528\u6cd5\uff09" ;;
  esac
done

# ---------------------------------------------------------------- 环境检查
[ -n "$PREFIX" ] || die "\u8bf7\u5728 Termux \u4e2d\u8fd0\u884c\u672c\u811a\u672c\u3002"

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ARCH="arm64" ;;
  armv7l|armv8l|arm) die "LinuxQQ \u5b98\u65b9\u672a\u63d0\u4f9b 32 \u4f4d ARM \u5b89\u88c5\u5305\uff0c\u8bf7\u4f7f\u7528 arm64 \u8bbe\u5907\u3002" ;;
  x86_64|amd64) ARCH="amd64" ;;
  *) warn "\u672a\u77e5\u67b6\u6784 $ARCH\uff0c\u53ef\u80fd\u5931\u8d25\u3002" ;;
  ;;
esac

printf "\n${B}\u7b2c\u4e8c\u4e2a${N} \u00b7 QQ Bot on Android   \u67b6\u6784: ${Y}%s${N}\n\n" "$ARCH"

# ---------------------------------------------------------------- 基础依赖
info "\u68c0\u67e5 Termux \u57fa\u7840\u4f9d\u8d56\u2026\u2026"
pkg install -y proot-distro screen curl || die "\u57fa\u7840\u4f9d\u8d56\u5b89\u88c5\u5931\u8d25\uff0c\u8bf7\u5148\u6267\u884c: pkg update && pkg upgrade"
ok "proot-distro / screen / curl \u5c31\u7eea"

# ---------------------------------------------------------------- 存储权限
if [ ! -d "$HOME/storage/downloads" ] && command -v termux-setup-storage >/dev/null 2>&1; then
  warn "\u7533\u8bf7\u5b58\u50a8\u6743\u9650\uff08\u7528\u4e8e\u4fdd\u5b58\u4e8c\u7ef4\u7801\u5230\u76f8\u518c\uff09\uff0c\u8bf7\u5728\u5f39\u7a97\u70b9\u300c\u5141\u8bb8\u300d"
  termux-setup-storage
  sleep 4
fi

# ---------------------------------------------------------------- 创建容器
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$ALIAS"

if [ -d "$ROOTFS/root" ]; then
  if [ "$RESUME" = 1 ]; then
    ok "\u590d\u7528\u5df2\u6709\u5bb9\u5668\uff1a$ALIAS"
  else
    warn "\u5bb9\u5668 $ALIAS \u5df2\u5b58\u5728\uff0c\u8df3\u8fc7\u521b\u5efa\uff08\u60f3\u91cd\u88c5\uff1aproot-distro remove $ALIAS\uff09"
  fi
else
  info "\u4e0b\u8f7d\u5e76\u521b\u5efa Debian \u5bb9\u5668\uff08150MB \u5de6\u53f3\uff0c1~10 \u5206\u949f\uff09\u2026\u2026"
  proot-distro install "$IMAGE" --override-alias "$ALIAS" \
    || proot-distro install debian --override-alias "$ALIAS" \
    || proot-distro install ubuntu --override-alias "$ALIAS" \
    || die "\u5bb9\u5668\u521b\u5efa\u5931\u8d25\u3002\u8bf7\u68c0\u67e5\u7f51\u7edc\uff0c\u6216\u624b\u52a8\u6267\u884c: proot-distro install debian"
  ok "\u5bb9\u5668\u521b\u5efa\u5b8c\u6210"
fi

# ---------------------------------------------------------------- 容器内安装
info "\u5f00\u59cb\u5b89\u88c5 LinuxQQ + NapCat\uff0810~30 \u5206\u949f\uff0c\u8bf7\u4fdd\u6301 Termux \u524d\u53f0 \u2615\uff09"

if proot-distro login "$ALIAS" -- bash -c "export CN='$USE_CN' GHPROXY='$GHPROXY'; bash -s" <<'INNER'
set -e
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

if [ "$CN" = "1" ]; then
  echo "   \u00b7 \u5207\u6362 Debian \u955c\u50cf\u6e90 \u2192 \u6e05\u534e TUNA"
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do
    if [ -f "$f" ]; then
      sed -i -e 's|https\?://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' \
             -e 's|https\?://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' "$f"
    fi
  done
fi

echo "   \u00b7 \u66f4\u65b0\u8f6f\u4ef6\u5305\u7d22\u5f15"
apt-get update -y -qq
apt-get install -y -qq sudo curl ca-certificates libgcrypt20 xz-utils jq unzip procps

echo "   \u00b7 \u4e0b\u8f7d NapCat \u5b98\u65b9\u5b89\u88c5\u5668"
URL="https://raw.githubusercontent.com/NapNeko/NapCat-Installer/main/script/install.sh"
if [ -n "$GHPROXY" ]; then URL="$GHPROXY/$URL"; fi
curl -fsSL --connect-timeout 20 --max-time 1800 "$URL" -o /tmp/napcat-installer.sh
head -c 2 /tmp/napcat-installer.sh | grep -q '#!' || { echo "\u4e0b\u8f7d\u5185\u5bb9\u975e\u811a\u672c"; exit 1; }

echo "   \u00b7 \u6267\u884c\u5b89\u88c5\uff08\u4e0b\u8f7d LinuxQQ + NapCat\uff0c\u9700\u8981\u51e0\u5206\u949f\uff09"
bash /tmp/napcat-installer.sh --docker n --cli n --github-proxy "${GHPROXY:-0}"
apt-get clean
INNER
then
  ok "NapCat \u5b89\u88c5\u5b8c\u6210"
else
  die "NapCat \u5b89\u88c5\u5931\u8d25\u3002\u53ef\u91cd\u8bd5\uff1abash install.sh --resume"
fi

# ---------------------------------------------------------------- second 命令
info "\u5b89\u88c5 second \u7ba1\u7406\u547d\u4ee4\u2026\u2026"
mkdir -p "$PREFIX/bin" "$HOME/.second-bot"
if curl -fsSL --max-time 60 "$RAW/scripts/second.sh" -o "$PREFIX/bin/second" 2>/dev/null; then
  ok "second \u547d\u4ee4\u5df2\u4e0b\u8f7d"
elif [ -f "./scripts/second.sh" ]; then
  cp ./scripts/second.sh "$PREFIX/bin/second"
  ok "second \u547d\u4ee4\u5df2\u4ece\u672c\u5730\u590d\u5236"
else
  warn "second \u547d\u4ee4\u4e0b\u8f7d\u5931\u8d25\uff0c\u53ef\u7a0d\u540e\u91cd\u8bd5"
fi
if [ -f "$PREFIX/bin/second" ]; then
  sed -i "s|^ALIAS=.*|ALIAS=\"$ALIAS\"|" "$PREFIX/bin/second"
  chmod +x "$PREFIX/bin/second"
fi

# ---------------------------------------------------------------- 图形面板
if [ "$WITH_PANEL" = 1 ]; then
  info "\u5b89\u88c5\u56fe\u5f62\u9762\u677f\u2026\u2026"
  pkg install -y nodejs || warn "Node.js \u5b89\u88c5\u5931\u8d25\uff0c\u9762\u677f\u5c06\u4e0d\u53ef\u7528"

  if curl -fsSL --max-time 60 "$RAW/panel/server.js" -o "$HOME/.second-bot/server.js" 2>/dev/null; then
    ok "\u9762\u677f\u5df2\u4e0b\u8f7d"
  elif [ -f "./panel/server.js" ]; then
    cp ./panel/server.js "$HOME/.second-bot/server.js"
    ok "\u9762\u677f\u5df2\u4ece\u672c\u5730\u590d\u5236"
  else
    warn "\u9762\u677f\u4e0b\u8f7d\u5931\u8d25\uff0c\u7a0d\u540e\u53ef\u91cd\u8bd5"
  fi
fi

# ---------------------------------------------------------------- 完成
printf "\n${G}\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500${N}\n"
cat <<EOF
 \ud83c\udf89 \u5b89\u88c5\u5b8c\u6210\uff01\n
 \u542f\u52a8\u673a\u5668\u4eba\uff1a   ${Y}second start${N}
 \u770b\u65e5\u5fd7\uff1a       ${Y}second log${N}
 \u4fdd\u5b58\u4e8c\u7ef4\u7801\uff1a   ${Y}second qr${N}
 \u6253\u5f00\u9762\u677f\uff1a   ${Y}second panel${N}   \u6d4f\u89c8\u5668 http://127.0.0.1:8090
 \u505c\u6b62\uff1a       ${Y}second stop${N}

 \u9996\u6b21\u767b\u5f55\u5efa\u8bae\uff1a
   1. second start
   2. second qr       \u2190 \u4e8c\u7ef4\u7801\u5b58\u5230 /sdcard/Download/qrcode.png
   3. \u624b\u673a QQ\u300c\u626b\u4e00\u626b \u2192 \u76f8\u518c\u300d\u9009\u90a3\u5f20\u56fe \u2728
EOF
