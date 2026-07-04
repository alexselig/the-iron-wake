#!/usr/bin/env python3
"""Local web app to blind-review Iron Wake voice settings.

Serves /tmp/voice_review (clips + the review UI) and accepts the submitted
preferences at POST /save -> /tmp/voice_review/results.json.

    python3 tools/generate_voice_review.py   # make the clips first
    python3 tools/voice_review_server.py      # then open the printed URL
"""
import json
import os
import http.server
import socketserver

REVIEW_DIR = "/tmp/voice_review"
PORT = 8777
INDEX = "index.html"


PAGE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Iron Wake — Voice Review</title>
<style>
  :root { --bg:#12141a; --panel:#1b1f28; --line:#2a2f3a; --text:#e6e9ef;
          --dim:#9aa3b2; --accent:#6c8ef5; --good:#3ecf8e; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--text);
         font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif; }
  header { position:sticky; top:0; background:var(--bg); border-bottom:1px solid var(--line);
           padding:16px 20px; display:flex; align-items:center; gap:16px; z-index:5; }
  h1 { font-size:17px; margin:0; }
  .progress { color:var(--dim); font-size:13px; }
  .wrap { max-width:820px; margin:0 auto; padding:20px; }
  .card { background:var(--panel); border:1px solid var(--line); border-radius:12px;
          padding:16px 18px; margin-bottom:16px; }
  .spk { font-size:11px; letter-spacing:.5px; text-transform:uppercase; color:var(--accent);
         font-weight:700; }
  .line { font-size:16px; margin:4px 0 14px; }
  .opts { display:flex; flex-wrap:wrap; gap:10px; }
  .opt { display:flex; align-items:center; gap:8px; background:#151922; border:1px solid var(--line);
         border-radius:9px; padding:8px 12px; cursor:pointer; user-select:none; }
  .opt.sel { border-color:var(--good); box-shadow:inset 0 0 0 1px var(--good); }
  .opt button { background:var(--accent); color:#0b0d12; border:none; border-radius:6px;
                width:30px; height:30px; font-size:14px; cursor:pointer; }
  .opt button.playing { background:var(--good); }
  .opt .lbl { font-variant-numeric:tabular-nums; }
  .opt input { accent-color:var(--good); width:16px; height:16px; }
  .none { margin-top:10px; }
  .none label { color:var(--dim); font-size:13px; cursor:pointer; }
  .bar { position:sticky; bottom:0; background:var(--bg); border-top:1px solid var(--line);
         padding:14px 20px; display:flex; gap:12px; align-items:center; justify-content:flex-end; }
  .btn { background:var(--accent); color:#0b0d12; border:none; border-radius:8px;
         padding:10px 18px; font-weight:650; cursor:pointer; }
  .btn:disabled { opacity:.4; cursor:not-allowed; }
  .msg { color:var(--good); margin-right:auto; }
</style></head>
<body>
<header><h1>🎙 Iron Wake — Voice Review</h1>
  <span class="progress" id="progress"></span></header>
<div class="wrap" id="list"></div>
<div class="bar"><span class="msg" id="msg"></span>
  <span class="progress" id="count"></span>
  <button class="btn" id="submit" disabled>Submit preferences</button></div>
<script>
let DATA=null, choices={};
const $=s=>document.querySelector(s);

async function load(){
  DATA = await (await fetch('review.json')).json();
  const list=$('#list');
  DATA.items.forEach(it=>{
    const card=document.createElement('div'); card.className='card';
    card.innerHTML=`<div class="spk">${it.speaker}</div><div class="line">${it.text}</div>`;
    const opts=document.createElement('div'); opts.className='opts';
    it.options.forEach((o,i)=>{
      const el=document.createElement('div'); el.className='opt';
      el.innerHTML=`<button title="Play">▶</button><span class="lbl">Option ${i+1}</span>
        <input type="radio" name="q${it.id}" title="Prefer this">`;
      const audio=new Audio(o.file);
      const btn=el.querySelector('button');
      btn.onclick=e=>{ e.stopPropagation();
        document.querySelectorAll('audio').forEach(a=>a.pause());
        document.querySelectorAll('.opt button').forEach(b=>b.classList.remove('playing'));
        btn.classList.add('playing'); audio.currentTime=0; audio.play();
        audio.onended=()=>btn.classList.remove('playing'); };
      el.querySelector('audio')||null;
      const radio=el.querySelector('input');
      const choose=()=>{ choices[it.id]=o.profile;
        opts.querySelectorAll('.opt').forEach(x=>x.classList.remove('sel'));
        el.classList.add('sel'); radio.checked=true; update(); };
      el.onclick=choose; radio.onclick=e=>{e.stopPropagation();choose();};
      opts.appendChild(el);
    });
    card.appendChild(opts);
    const none=document.createElement('div'); none.className='none';
    none.innerHTML=`<label><input type="radio" name="q${it.id}"> No preference / all similar</label>`;
    none.querySelector('input').onclick=()=>{ choices[it.id]='__none__';
      opts.querySelectorAll('.opt').forEach(x=>x.classList.remove('sel')); update(); };
    card.appendChild(none);
    list.appendChild(card);
  });
  update();
}
function update(){
  const n=Object.keys(choices).length, total=DATA.items.length;
  $('#progress').textContent=`${n}/${total} rated`;
  $('#count').textContent=`${n}/${total}`;
  $('#submit').disabled = n===0;
}
$('#submit').onclick=async()=>{
  const res={submitted:new Date().toISOString(), choices, profiles:DATA.profiles,
    map:Object.fromEntries(DATA.items.map(it=>[it.id,{speaker:it.speaker,text:it.text,
      options:it.options}]))};
  await fetch('save',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify(res)});
  $('#msg').textContent='Saved! You can tell the agent to interpret the results.';
  $('#submit').textContent='Saved ✓';
};
load();
</script></body></html>"""


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=REVIEW_DIR, **k)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            body = PAGE.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        return super().do_GET()

    def do_POST(self):
        if self.path.rstrip("/") == "/save":
            n = int(self.headers.get("Content-Length", 0))
            data = self.rfile.read(n)
            with open(os.path.join(REVIEW_DIR, "results.json"), "wb") as f:
                f.write(data)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
            print("  ✓ preferences saved to results.json")
            return
        self.send_error(404)

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    if not os.path.isfile(os.path.join(REVIEW_DIR, "review.json")):
        raise SystemExit("No review.json — run: python3 tools/generate_voice_review.py")
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print(f"Voice review app: http://127.0.0.1:{PORT}/")
        print("Play each option, pick your favorite per line, then Submit.")
        print("Ctrl-C to stop.")
        httpd.serve_forever()
