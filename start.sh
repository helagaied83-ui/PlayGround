#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p pwd
PORT="${PORT:-3000}"
export PORT
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
PROJECT_ROOT="$(printf '%s' "$PROJECT_ROOT" | tr -d '\n')"
DIST_DIR="$PROJECT_ROOT/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$DIST_DIR" "$WEB_DIR"
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p test -f "$DIST_DIR/index.html"; then
    echo "dist already built, skipping build"
  else
    /usr/bin/time -p npm run build --if-present
  fi
fi
/usr/bin/time -p test -f "$DIST_DIR/index.html"
/usr/bin/time -p node -e 'const fs=require("fs"),path=require("path");const root=process.cwd();const dist=path.join(root,"dist");const web=process.env.OPENCODE_WEB_DIR||"/home/runner/work/_temp/omgithub-web";fs.mkdirSync(web,{recursive:true});const out={project:root,directory:dist};fs.writeFileSync(path.join(web,"deployment-output.json"),JSON.stringify(out));console.log("deployment-output:",JSON.stringify(out));'
exec /usr/bin/time -p node -e '
const http=require("http"),fs=require("fs"),path=require("path");
const root=process.cwd(),dist=path.join(root,"dist");
const port=Number(process.env.PORT||3000);
const mime={".html":"text/html; charset=utf-8",".js":"application/javascript; charset=utf-8",".css":"text/css; charset=utf-8",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".webp":"image/webp",".ico":"image/x-icon",".woff2":"font/woff2",".wasm":"application/wasm"};
const server=http.createServer((req,res)=>{
  try{
    const u=new URL(req.url,"http://localhost");
    let rel=decodeURIComponent(u.pathname);
    if(rel.endsWith("/"))rel+="index.html";
    const file=path.resolve(dist,"."+rel);
    if(file!==dist&&!file.startsWith(dist+"/")){res.writeHead(404);res.end("Not found");return;}
    let target=file;
    try{if(fs.statSync(target).isDirectory())target=path.join(target,"index.html");}catch{}
    const data=fs.readFileSync(target);
    res.writeHead(200,{"Content-Type":mime[path.extname(target).toLowerCase()]||"application/octet-stream","Cache-Control":"no-cache"});
    res.end(data);
  }catch{res.writeHead(404);res.end("Not found");}
});
server.listen(port,"0.0.0.0",()=>console.log("Serving "+dist+" on port "+port));
'
