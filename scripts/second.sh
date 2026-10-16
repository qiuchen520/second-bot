#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
#  第二个 · 命令行管理工具
#  安装后可直接用: second start | stop | log | qr | panel | shell | config
# ============================================================================
ALIAS="napcat"
SESS="second-napcat"
DIR="$HOME/.second-bot"
LOG="$DIR/napcat.log"
PANEL_LOG="$DIR/panel.log"
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$ALIAS"
START_CMD="xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox"
NAPCAT_BASE="/root/Napcat/opt/QQ/resources/app/app_launcher/napcat"

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'
info(){ printf "${C}▸${N} %s\n" "$*"; }
ok(){   printf "${G}✔${N} %s\n" "$*"; }
warn(){ printf "${Y}!${N} %s\n" "$*"; }
err(){  printf "${R}✘${N} %s\n" "$*"; }

mkdir -p "$DIR"

is_running(){ screen -ls 2>/dev/null | grep -q "\.$SESS"; }

cmd_start(){
  if is_running; then warn "机器人已经在运行了（second log 看日志）"; return 0; fi
  if [ ! -d "$ROOTFS/root" ]; then err "容器不存在，请先运行 install.sh"; return 1; fi
  : > "$LOG" 2>/dev/null
  screen -L -Logfile "$LOG" -dmS "$SESS" \
    proot-distro login "$ALIAS" -- bash -c "$START_CMD"
  sleep 2
  if is_running; then
    ok "已启动"
    info "查看日志: second log"
    info "保存二维码: second qr"
  else
    err "启动失败，看看日志: cat $LOG"
    return 1
  fi
}

cmd_stop(){
  if ! is_running; then warn "当前没有运行"; return 0; fi
  screen -S "$SESS" -X quit 2>/dev/null
  pkill -f "proot-distro login $ALIAS" 2>/dev/null
  pkill -f "/root/Napcat/opt/QQ" 2>/dev/null
  sleep 1
  if is_running; then err "停止失败，请手动: screen -S $SESS -X quit"; else ok "已停止"; fi
}

cmd_status(){
  if is_running; then ok "运行中（screen 会话: $SESS）"; else warn "未运行"; fi
  echo "  容器路径: $ROOTFS"
  echo "  运行日志: $LOG"
}

cmd_log(){
  if [ ! -f "$LOG" ]; then err "还没有日志，先执行 second start"; return 1; fi
  info "实时日志（按 Ctrl+C 退出）"
  tail -f "$LOG"
}

find_qr(){
  local p="$ROOTFS/root/Napcat/opt/QQ/resources/app/app_launcher/napcat/cache/qrcode.png"
  if [ -f "$p" ]; then echo "$p"; return; fi
  find "$ROOTFS/root/Napcat" -name 'qrcode.png' -type f 2>/dev/null | head -n 1
}

cmd_qr(){
  local qr; qr="$(find_qr)"
  if [ -z "$qr" ] || [ ! -f "$qr" ]; then
    err "没找到二维码。请先 second start，等生成后再执行本命令。"
    return 1
  fi
  cp "$qr" /sdcard/Download/qrcode.png 2>/dev/null \
    && ok "二维码已保存: /sdcard/Download/qrcode.png" \
    || { cp "$qr" "$HOME/qrcode.png" && ok "二维码已保存: $HOME/qrcode.png"; }
  echo "  📷 手机 QQ →「扫一扫」→ 右上角「相册」→ 选这张图"
}

cmd_shell(){ proot-distro login "$ALIAS"; }

cmd_config(){
  cat <<EOF
配置目录（容器内）:
  $NAPCAT_BASE/config

在 Termux 中直接访问的路径:
  $ROOTFS/root/Napcat/opt/QQ/resources/app/app_launcher/napcat/config

NapCat 默认端口:
  WebUI  6099   (默认 token: napcat)
  HTTP   3000
  WS     3001
EOF
}

cmd_panel(){
  if ! command -v node >/dev/null 2>&1; then
    err "缺少 Node.js，请执行: pkg install nodejs"; return 1
  fi
  if [ ! -f "$DIR/server.js" ]; then err "面板文件缺失: $DIR/server.js"; return 1; fi
  if pgrep -f "$DIR/server.js" >/dev/null 2>&1; then
    warn "面板已经在运行了"
  else
    SECOND_ALIAS="$ALIAS" nohup node "$DIR/server.js" > "$PANEL_LOG" 2>&1 &
    sleep 1
  fi
  ok "面板已启动"
  info "本机浏览器打开: http://127.0.0.1:8090"
  info "同一 WiFi 下的其他设备: http://<手机IP>:8090"
  info "关闭面板: pkill -f server.js"
}

usage(){
  printf "${B}第二个${N} · 命令行工具\n\n"
  cat <<EOF
用法: second <命令>

  ${G}start${N}      启动机器人（后台运行）
  ${G}stop${N}       停止机器人
  ${G}status${N}     查看运行状态
  ${G}log${N}        实时查看日志（Ctrl+C 退出）
  ${G}qr${N}         把登录二维码保存到相册
  ${G}panel${N}      启动手机图形面板
  ${G}shell${N}      进入容器内部
  ${G}config${N}     显示配置路径与端口
  ${G}help${N}       显示本帮助
EOF
}

case "${1:-help}" in
  start)        cmd_start ;;
  stop)         cmd_stop ;;
  status|st)    cmd_status ;;
  log|logs)     cmd_log ;;
  qr|scan)      cmd_qr ;;
  panel|gui)    cmd_panel ;;
  shell|sh)     cmd_shell ;;
  config|cfg)   cmd_config ;;
  help|-h|--help) usage ;;
  *)            err "未知命令: $1"; echo; usage; exit 1 ;;
esac
