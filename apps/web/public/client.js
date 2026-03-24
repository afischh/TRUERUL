(function () {
  const terminalEl = document.getElementById('terminal');
  const statusEl = document.getElementById('connection-status');
  const buttons = document.querySelectorAll('[data-insert], [data-command], [data-send]');

  function setStatus(text, color) {
    statusEl.textContent = text;
    if (color) statusEl.style.color = color;
  }

  if (!window.Terminal) {
    setStatus('xterm missing', '#cf6a6a');
    terminalEl.textContent = 'TRUERUL boot error: xterm.js did not load.';
    return;
  }

  const TerminalCtor = window.Terminal;
  const FitAddonCtor = window.FitAddon && (window.FitAddon.FitAddon || window.FitAddon);

  const term = new TerminalCtor({
    cursorBlink: true,
    fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
    fontSize: 15,
    lineHeight: 1.18,
    letterSpacing: 0,
    convertEol: true,
    scrollback: 2000,
    theme: {
      background: '#060a0d',
      foreground: '#c8d0d6',
      cursor: '#88c0d0',
      black: '#060a0d',
      red: '#cf6a6a',
      green: '#84b68a',
      yellow: '#c8b56a',
      blue: '#88c0d0',
      magenta: '#b79ac8',
      cyan: '#88c0d0',
      white: '#c8d0d6',
      brightBlack: '#59656d',
      brightRed: '#e07d7d',
      brightGreen: '#97c79b',
      brightYellow: '#d8c57a',
      brightBlue: '#9cd1e0',
      brightMagenta: '#c4abd2',
      brightCyan: '#9cd1e0',
      brightWhite: '#f2f4f6'
    }
  });

  let fitAddon = null;
  if (FitAddonCtor) {
    fitAddon = new FitAddonCtor();
    term.loadAddon(fitAddon);
  }

  const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
  const ws = new WebSocket(protocol + '://' + window.location.host + '/ws');
  const attachState = { wsOpen: false, ptyReady: false };

  function scrollViewportToBottom() {
    const viewport = terminalEl.querySelector('.xterm-viewport');
    if (viewport) viewport.scrollTop = viewport.scrollHeight;
    term.scrollToBottom();
  }

  function stabilizeViewport() {
    window.requestAnimationFrame(function () {
      scrollViewportToBottom();
      term.focus();
    });
  }

  function fitAndResize() {
    if (fitAddon) fitAddon.fit();
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'resize',
        cols: term.cols,
        rows: term.rows
      }));
    }
    stabilizeViewport();
  }

  function scheduleFitSequence() {
    fitAndResize();
    setTimeout(fitAndResize, 20);
    setTimeout(fitAndResize, 80);
  }

  function sendInput(text, withEnter) {
    if (ws.readyState !== WebSocket.OPEN) return;
    const payload = withEnter ? text + '\r' : text;
    ws.send(JSON.stringify({ type: 'input', data: payload }));
    stabilizeViewport();
  }

  setStatus('booting', '#c8b56a');
  term.open(terminalEl);
  scheduleFitSequence();

  ws.addEventListener('open', function () {
    attachState.wsOpen = true;
    if (!attachState.ptyReady) {
      setStatus('ws open', '#c8b56a');
    }
    scheduleFitSequence();
  });

  ws.addEventListener('message', function (event) {
    try {
      const msg = JSON.parse(event.data);
      if (msg.type === 'ready') {
        attachState.ptyReady = true;
        setStatus('attached', '#84b68a');
        scheduleFitSequence();
        return;
      }
      if (msg.type === 'data' && typeof msg.data === 'string') {
        term.write(msg.data);
        stabilizeViewport();
      }
    } catch (_err) {
      term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m malformed server frame');
      stabilizeViewport();
    }
  });

  ws.addEventListener('close', function () {
    setStatus('closed', '#cf6a6a');
    term.writeln('\r\n\x1b[31m[closed]\x1b[0m websocket closed');
    stabilizeViewport();
  });

  ws.addEventListener('error', function () {
    setStatus('ws error', '#cf6a6a');
    term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m websocket error');
    stabilizeViewport();
  });

  term.onData(function (data) {
    sendInput(data, false);
  });

  buttons.forEach(function (button) {
    const keepFocus = function (evt) {
      evt.preventDefault();
      term.focus();
    };
    button.addEventListener('mousedown', keepFocus);
    button.addEventListener('touchstart', keepFocus, { passive: false });
    button.addEventListener('click', function () {
      const insert = button.getAttribute('data-insert');
      const command = button.getAttribute('data-command');
      const legacy = button.getAttribute('data-send');
      if (insert) {
        sendInput(insert, false);
      } else if (command) {
        sendInput(command, button.getAttribute('data-enter') === '1');
      } else if (legacy) {
        const data = legacy.replace(/\\r/g, '\r').replace(/\\n/g, '\n');
        sendInput(data, false);
      }
      term.focus();
      stabilizeViewport();
    });
  });

  terminalEl.addEventListener('click', function () {
    term.focus();
    stabilizeViewport();
  });

  window.addEventListener('resize', scheduleFitSequence);
  window.addEventListener('orientationchange', function () {
    setTimeout(scheduleFitSequence, 50);
  });
  window.addEventListener('load', scheduleFitSequence);

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', function () {
      setTimeout(scheduleFitSequence, 10);
    });
  }

  if (window.ResizeObserver) {
    const observer = new ResizeObserver(function () {
      scheduleFitSequence();
    });
    observer.observe(terminalEl);
  }
})();
