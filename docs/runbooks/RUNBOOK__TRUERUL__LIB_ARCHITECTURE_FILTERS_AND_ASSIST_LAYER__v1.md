# RUNBOOK — Truerul .lib architecture, filters, and assist-layer (v1)

Date: 2026-03-24
Root: `/srv/truerul`

## 1) Restart web runtime

```bash
cd /srv/truerul
pkill -f 'node apps/web/server.js' || true
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
```

## 2) `.lib` smoke in console

```bash
cd /srv/truerul
printf '(lib-индекс)\n(lib-список)\n(lib-подобрать :domain logic :logic-mode paraconsistent)\n(оператор "если есть противоречие в связи" :domain logic :cost 5)\n' | timeout 40s bash lisp/scripts/run_truerul.sh
```

## 3) Optional LLM-assist adapter

By default runtime uses heuristic assist only.

To enable local lightweight OSS model via adapter:

```bash
export TRUERUL_ASSIST_USE_OLLAMA=1
export TRUERUL_ASSIST_MODEL='qwen2.5:1.5b-instruct'
export TRUERUL_ASSIST_CMD='/srv/truerul/scripts/assist/truerul_assist_local.sh --role {{role}} --input {{input}}'
```

Then:

```bash
cd /srv/truerul
printf '(ассист "если есть противоречие в связи" :role parse-assist)\n' | timeout 30s bash lisp/scripts/run_truerul.sh
```

## 4) Operator pipeline demo

```bash
cd /srv/truerul
printf '(оператор "если есть противоречие в связи" :domain logic :cost 5)\n(оператор "нужно типовое суждение" :domain foundations :input-kind type-judgement :cost 5)\n' | timeout 30s bash lisp/scripts/run_truerul.sh
```

Expected:
- classified output,
- selected `.lib`,
- route lines,
- normalized forms.

## 5) Browser verification markers

```bash
curl -sS http://127.0.0.1:4173/ | rg -n '\\.lib|lib-индекс|ассист|оператор|optgroup label="\\.lib / Assist"'
```
