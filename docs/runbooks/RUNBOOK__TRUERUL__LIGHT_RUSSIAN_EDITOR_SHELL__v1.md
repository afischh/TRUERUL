# RUNBOOK — Truerul Light Russian Editor Shell v1

## 1) Что это

`Workbench/Editor v0` — лёгкая русская оболочка поверх живой консоли Truerul:
- центральный реальный xterm/PTY
- буфер форм
- библиотечные кнопки
- виды/схемы
- просмотр saved artifacts
- палитра команд
- обязательное действие `Назад`

Shell не заменяет консоль и не ломает обычный terminal/tmux contour.

## 2) Запуск на VPS

```bash
cd /srv/truerul
npm ci
TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js
```

Открыть:
- `http://127.0.0.1:4173/`
- или внешний адрес с cache-buster: `http://<host>:4173/?v=editor-shell-v1`

## 3) Запуск в tmux на VPS

```bash
tmux has-session -t truerul-web 2>/dev/null && tmux kill-session -t truerul-web || true
tmux new-session -d -s truerul-web 'cd /srv/truerul && TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js'
tmux attach -t truerul-web
```

## 4) Проверки

```bash
curl -sS http://127.0.0.1:4173/health
curl -sS 'http://127.0.0.1:4173/api/artifacts?bucket=notes'
```

## 5) Поток работы в shell

1. Пиши формы в `Буфер форм`.
2. Отправляй `Выполнить строку` / `Выполнить выделенное` / `Выполнить буфер`.
3. Сохраняй блок через `имя-блока` + `Сохранить блок`.
4. Смотри `Виды` и открывай saved artifacts.
5. Вставляй artifact обратно в буфер или выполняй формы из него.
6. Используй кнопку `Назад` для возврата по pane-истории (или отправки `(назад)` в runtime).

## 6) Downstream на ноутбук (после Git sync)

На VPS:
```bash
cd /srv/truerul
git push
```

На ноутбуке:
```bash
cd ~/path/to/truerul
git pull --ff-only
npm ci
TRUERUL_RUNTIME=lisp TRUERUL_WEB_PORT=4173 node apps/web/server.js
```

Открыть локально:
- `http://127.0.0.1:4173/`

## 7) Важно

Обычный режим без web shell остаётся каноническим и рабочим:
```bash
cd /srv/truerul
bash lisp/scripts/run_truerul.sh
```
