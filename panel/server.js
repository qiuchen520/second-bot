// ============================================================================
//  QBot · 手机图形面板
//  运行: QBOT_ALIAS=napcat node server.js   然后浏览器打开 http://127.0.0.1:8090
// ============================================================================
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const PORT = Number(process.env.QBOT_PORT || process.env.SECOND_PORT || 8090);
const ALIAS = process.env.QBOT_ALIAS || process.env.SECOND_ALIAS || 'napcat';
const SESS = process.env.QBOT_SESSION || 'qbot-napcat';
const HOME_DIR = process.env.HOME || '/data/data/com.termux/files/home';
const DIR = path.join(HOME_DIR, '.qbot');
const LOG = path.join(DIR, 'napcat.log');
const PREFIX = process.env.PREFIX || '/data/data/com.termux/files/usr';
const ROOTFS = path.join(PREFIX, 'var/lib/proot-distro/installed-rootfs', ALIAS);
const NAPCAT_HOME = path.join(ROOTFS, 'root/Napcat');
const START_CMD = 'xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox';
const QR_DEST = '/sdcard/Download/qrcode.png';

function sh(cmd) {
  return new Promise(function (resolve) {
    execFile('/bin/sh', ['-c', cmd], { timeout: 30000 }, function (e, so, se) {
      resolve({ code: e ? 1 : 0, out: (so || '').toString(), err: (se || '').toString() });
    });
  });
}

async function isRunning() {
  const r = await sh('screen -ls 2>/dev/null | grep -q "\\.' + SESS + '" && echo YES || echo NO');
  return r.out.trim() === 'YES';
}

function tailLog(n) {
  try {
    const s = fs.readFileSync(LOG, 'utf8');
    return s.split('\n').slice(-n).join('\n').trim();
  } catch (e) { return ''; }
}

function countLines() {
  try { return fs.readFileSync(LOG, 'utf8').split('\n').length; } catch (e) { return 0; }
}

// 递归找 qrcode.png（限制深度，避免全盘扫描拖慢手机）
function findQr(dir, depth) {
  depth = depth || 0;
  if (depth > 8) return null;
  let ents;
  try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return null; }
  for (const e of ents) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      const r = findQr(p, depth + 1);
      if (r) return r;
    } else if (e.name.toLowerCase() === 'qrcode.png') {
      return p;
    }
  }
  return null;
}

async function doStart() {
  if (await isRunning()) return { ok: true, msg: '已经在运行了' };
  if (!fs.existsSync(path.join(ROOTFS, 'root'))) return { ok: false, msg: '容器不存在，请先运行 install.sh' };
  try { fs.writeFileSync(LOG, ''); } catch (e) {}
  const cmd = 'screen -L -Logfile ' + JSON.stringify(LOG) + ' -dmS ' + SESS +
    ' proot-distro login ' + ALIAS + ' -- bash -c ' + JSON.stringify(START_CMD) + ' &';
  await sh(cmd);
  await new Promise(function (r) { setTimeout(r, 3000); });
  const ok = await isRunning();
  return { ok: ok, msg: ok ? '已启动' : '启动失败，请看日志' };
}

async function doStop() {
  if (!(await isRunning())) return { ok: true, msg: '当前没有运行' };
  await sh('screen -S ' + SESS + ' -X quit 2>/dev/null; pkill -f "proot-distro login ' + ALIAS + '" 2>/dev/null; pkill -f "/root/Napcat/opt/QQ" 2>/dev/null');
  await new Promise(function (r) { setTimeout(r, 1200); });
  return { ok: true, msg: '已停止' };
}

async function doSaveQr() {
  const qr = findQr(NAPCAT_HOME);
  if (!qr) return { ok: false, msg: '没找到二维码，请先启动机器人' };
  try {
    fs.mkdirSync('/sdcard/Download', { recursive: true });
    fs.copyFileSync(qr, QR_DEST);
    return { ok: true, msg: '已保存到相册: Download/qrcode.png' };
  } catch (e) {
    const alt = path.join(HOME_DIR, 'qrcode.png');
    try { fs.copyFileSync(qr, alt); return { ok: true, msg: '已保存: ' + alt }; }
    catch (e2) { return { ok: false, msg: '保存失败: ' + e2.message }; }
  }
}

function sendJson(res, obj) {
  res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(obj));
}

const server = http.createServer(async function (req, res) {
  const url = (req.url || '/').split('?')[0];

  if (url === '/api/state') {
    const running = await isRunning();
    const qr = running ? findQr(NAPCAT_HOME) : null;
    return sendJson(res, {
      running: running,
      alias: ALIAS,
      hasQr: !!qr,
      log: tailLog(200),
      logLines: countLines()
    });
  }

  if (url === '/api/start' && req.method === 'POST') return sendJson(res, await doStart());
  if (url === '/api/stop' && req.method === 'POST') return sendJson(res, await doStop());
  if (url === '/api/qr' && req.method === 'POST') return sendJson(res, await doSaveQr());

  if (url === '/qr.png') {
    const qr = findQr(NAPCAT_HOME);
    if (!qr) { res.writeHead(404); return res.end('no qr'); }
    res.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'no-store' });
    return fs.createReadStream(qr).pipe(res);
  }

  if (url === '/' || url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return res.end(PAGE);
  }

  res.writeHead(404);
  res.end('404');
});

const PAGE = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#0e1116">
<title>QBot</title>
<style>
:root{--bg:#0e1116;--card:#161b22;--line:#232b36;--fg:#e6edf3;--dim:#8b949e;--ok:#3fb950;--bad:#f85149}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 -apple-system,system-ui,"PingFang SC","Noto Sans CJK SC",sans-serif;padding:18px 14px 40px}
h1{font-size:21px;margin:0;letter-spacing:1px}
.sub{color:var(--dim);font-size:12px;margin-top:3px}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px;margin-top:14px}
.row{display:flex;align-items:center;gap:10px}
.dot{width:10px;height:10px;border-radius:50%;background:var(--bad);flex:0 0 auto}
.dot.on{background:var(--ok);box-shadow:0 0 10px var(--ok)}
.btns{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:14px}
button{border:1px solid var(--line);background:#1c2430;color:var(--fg);padding:15px;border-radius:12px;font-size:15px;font-weight:600;cursor:pointer;transition:transform .08s}
button:active{transform:scale(.96)}
button.primary{background:#1f6feb;border-color:#1f6feb}
button.danger{background:#8b2a2a;border-color:#8b2a2a}
pre{background:#0b0f14;border:1px solid var(--line);border-radius:12px;padding:12px;font-size:11px;line-height:1.55;max-height:44vh;overflow:auto;white-space:pre-wrap;word-break:break-all;margin:10px 0 0}
img.qr{width:100%;max-width:280px;display:block;margin:0 auto;background:#fff;border-radius:12px;padding:10px}
.tip{color:var(--dim);font-size:12px}
.mono{font-family:ui-monospace,SFMono-Regular,monospace;font-size:11px;color:var(--dim);word-break:break-all;margin-top:6px}
</style>
</head>
<body>
<h1>QBot</h1>
<div class="sub">QQ Bot on Android · 图形面板</div>

<div class="card">
  <div class="row"><span class="dot" id="dot"></span><b id="state">检测中…</b></div>
  <div class="mono" id="meta"></div>
</div>

<div class="btns">
  <button class="primary" onclick="act('start')">启动</button>
  <button class="danger" onclick="act('stop')">停止</button>
  <button onclick="act('qr')">二维码存相册</button>
  <button onclick="refresh()">刷新状态</button>
</div>

<div class="card">
  <div class="row" style="justify-content:space-between">
    <b>登录二维码</b><span class="tip" id="qrtip"></span>
  </div>
  <div id="qrbox" style="margin-top:10px"></div>
  <div class="tip" style="margin-top:8px">同一个手机扫不了自己的屏幕 → 点「二维码存相册」，再用 QQ「扫一扫 → 相册」选图</div>
</div>

<div class="card">
  <b>运行日志</b>
  <pre id="log">加载中…</pre>
</div>

<script>
function el(id){return document.getElementById(id)}
var lastLog='';
function toast(t){el('qrtip').textContent=t||'';setTimeout(function(){el('qrtip').textContent=''},4500)}
function act(a){
  fetch('api/'+a,{method:'POST'}).then(function(r){return r.json()}).then(function(j){
    toast(j.msg||'完成');setTimeout(refresh,800);
  }).catch(function(){toast('操作失败')});
}
function refresh(){
  fetch('api/state').then(function(r){return r.json()}).then(function(s){
    el('dot').className='dot'+(s.running?' on':'');
    el('state').textContent=s.running?'运行中':'已停止';
    el('meta').textContent='容器 '+s.alias+' · 日志约 '+s.logLines+' 行';
    if(s.log!==lastLog){lastLog=s.log;el('log').textContent=s.log||'(暂无日志)';el('log').scrollTop=el('log').scrollHeight;}
    if(s.hasQr){
      if(!el('qrbox').querySelector('img')) el('qrbox').innerHTML='<img class="qr" src="qr.png">';
    }else{
      el('qrbox').innerHTML='<div class="tip">还没有二维码。点「启动」，等待 10~30 秒后刷新。</div>';
    }
  }).catch(function(){el('state').textContent='面板连接失败'});
}
refresh();setInterval(refresh,3000);
</script>
</body>
</html>`;

server.listen(PORT, '0.0.0.0', function () {
  console.log('QBot · 面板已启动');
  console.log('  本机: http://127.0.0.1:' + PORT);
  console.log('  容器: ' + ALIAS);
});
