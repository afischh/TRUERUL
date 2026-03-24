(function () {
  const terminalEl = document.getElementById('terminal');
  const statusEl = document.getElementById('connection-status');
  const menuTabs = document.querySelectorAll('.menu-tab[data-pane]');
  const paneNodes = document.querySelectorAll('.panel-pane[data-pane-content]');
  const backButton = document.getElementById('shell-back');

  const formBuffer = document.getElementById('form-buffer');
  const blockNameInput = document.getElementById('block-name');
  const schemeConceptInput = document.getElementById('scheme-concept');
  const recentCommandsEl = document.getElementById('recent-commands');

  const paletteSelect = document.getElementById('command-palette');
  const paletteInsertBtn = document.getElementById('palette-insert');
  const paletteRunBtn = document.getElementById('palette-run');

  const artifactBucketSelect = document.getElementById('artifact-bucket');
  const artifactRefreshBtn = document.getElementById('artifact-refresh');
  const artifactListEl = document.getElementById('artifact-list');
  const artifactPreviewEl = document.getElementById('artifact-preview');
  const artifactInsertBtn = document.getElementById('artifact-insert');
  const artifactRunBtn = document.getElementById('artifact-run');

  const bufferSendLineBtn = document.getElementById('buffer-send-line');
  const bufferSendSelectionBtn = document.getElementById('buffer-send-selection');
  const bufferSendAllBtn = document.getElementById('buffer-send-all');
  const bufferClearBtn = document.getElementById('buffer-clear');
  const blockSaveBtn = document.getElementById('block-save');
  const blockInsertBtn = document.getElementById('block-insert');

  const schemeRunBtn = document.getElementById('scheme-run');
  const schemeViewBtn = document.getElementById('scheme-view');
  const schemeSaveBtn = document.getElementById('scheme-save');

  let activePane = 'console';
  const paneHistory = ['console'];
  const recentCommands = [];

  let artifactCache = [];
  let selectedArtifact = null;

  function setStatus(text, color) {
    statusEl.textContent = text;
    if (color) statusEl.style.color = color;
  }

  function rememberCommand(command) {
    if (!command) return;
    const normalized = command.trim();
    if (!normalized) return;
    if (recentCommands[0] !== normalized) {
      recentCommands.unshift(normalized);
      if (recentCommands.length > 12) recentCommands.pop();
    }
    if (!recentCommandsEl) return;
    if (!recentCommands.length) {
      recentCommandsEl.textContent = 'Пока пусто.';
      return;
    }
    recentCommandsEl.innerHTML = recentCommands
      .map(function (item, index) {
        return (index + 1) + '. ' + item
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;');
      })
      .join('<br>');
  }

  function activatePane(name, pushHistory) {
    activePane = name;
    menuTabs.forEach(function (tab) {
      tab.classList.toggle('is-active', tab.getAttribute('data-pane') === name);
    });
    paneNodes.forEach(function (pane) {
      pane.classList.toggle('is-active', pane.getAttribute('data-pane-content') === name);
    });

    if (pushHistory) {
      if (paneHistory[paneHistory.length - 1] !== name) {
        paneHistory.push(name);
      }
    }

    if (name === 'views') {
      refreshArtifacts();
    }

    if (name === 'buffer' && formBuffer) {
      formBuffer.focus();
    }
  }

  function softBack() {
    if (paneHistory.length > 1) {
      paneHistory.pop();
      activatePane(paneHistory[paneHistory.length - 1], false);
      return;
    }
    sendCommand('(назад)');
  }

  function insertAtCursor(node, text) {
    if (!node) return;
    const start = node.selectionStart || 0;
    const end = node.selectionEnd || 0;
    const current = node.value || '';
    node.value = current.slice(0, start) + text + current.slice(end);
    const pos = start + text.length;
    node.selectionStart = pos;
    node.selectionEnd = pos;
    node.focus();
  }

  function currentLineFromTextarea(node) {
    if (!node) return '';
    const text = node.value || '';
    const cursor = node.selectionStart || 0;
    const lineStart = text.lastIndexOf('\n', Math.max(0, cursor - 1)) + 1;
    const nextBreak = text.indexOf('\n', cursor);
    const lineEnd = nextBreak === -1 ? text.length : nextBreak;
    return text.slice(lineStart, lineEnd).trim();
  }

  function splitCommandLines(text) {
    return String(text || '')
      .split(/\r?\n/)
      .map(function (line) {
        return line.trim();
      })
      .filter(Boolean);
  }

  function extractForms(text) {
    return splitCommandLines(text).filter(function (line) {
      return line.startsWith('(') && line.endsWith(')');
    });
  }

  function choosePayloadForBlock(text) {
    const forms = extractForms(text);
    if (!forms.length) return null;
    if (forms.length === 1) return forms[0];
    return '(progn ' + forms.join(' ') + ')';
  }

  if (!window.Terminal) {
    setStatus('xterm missing', '#cc7777');
    terminalEl.textContent = 'TRUERUL boot error: xterm.js did not load.';
    return;
  }

  const TerminalCtor = window.Terminal;
  const FitAddonCtor = window.FitAddon && (window.FitAddon.FitAddon || window.FitAddon);

  const term = new TerminalCtor({
    cursorBlink: true,
    fontFamily: 'Iosevka Term, JetBrains Mono, Fira Code, Source Code Pro, monospace',
    fontSize: 14,
    lineHeight: 1.2,
    convertEol: true,
    scrollback: 4000,
    theme: {
      background: '#040b11',
      foreground: '#cad5dc',
      cursor: '#7ec4de',
      black: '#040b11',
      red: '#cc7777',
      green: '#89ba91',
      yellow: '#c9a468',
      blue: '#7ec4de',
      magenta: '#bc9ac4',
      cyan: '#7ec4de',
      white: '#cad5dc',
      brightBlack: '#60707c',
      brightRed: '#dc8a8a',
      brightGreen: '#97c7a0',
      brightYellow: '#d8b67a',
      brightBlue: '#93d2e8',
      brightMagenta: '#c8acd1',
      brightCyan: '#93d2e8',
      brightWhite: '#f3f6f8'
    }
  });

  let fitAddon = null;
  if (FitAddonCtor) {
    fitAddon = new FitAddonCtor();
    term.loadAddon(fitAddon);
  }

  const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
  const ws = new WebSocket(protocol + '://' + window.location.host + '/ws');

  function scrollViewportToBottom() {
    const viewport = terminalEl.querySelector('.xterm-viewport');
    if (viewport) viewport.scrollTop = viewport.scrollHeight;
    term.scrollToBottom();
  }

  function stabilizeViewport() {
    window.requestAnimationFrame(scrollViewportToBottom);
  }

  function fitAndResize() {
    if (fitAddon) fitAddon.fit();
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'resize', cols: term.cols, rows: term.rows }));
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
    const payload = withEnter ? String(text) + '\r' : String(text);
    ws.send(JSON.stringify({ type: 'input', data: payload }));
    stabilizeViewport();
  }

  function sendCommand(command) {
    const cmd = String(command || '').trim();
    if (!cmd) return;
    rememberCommand(cmd);
    sendInput(cmd, true);
  }

  function sendCommandsFromText(text) {
    splitCommandLines(text).forEach(function (line) {
      sendCommand(line);
    });
  }

  function insertByContext(text) {
    if (activePane !== 'console' || document.activeElement === formBuffer) {
      insertAtCursor(formBuffer, text);
      return;
    }
    sendInput(text, false);
    term.focus();
  }

  async function fetchArtifacts(bucket) {
    const response = await fetch('/api/artifacts?bucket=' + encodeURIComponent(bucket));
    if (!response.ok) throw new Error('artifact_list_failed');
    return response.json();
  }

  async function fetchArtifact(bucket, file) {
    const response = await fetch('/api/artifacts/' + encodeURIComponent(bucket) + '/' + encodeURIComponent(file));
    if (!response.ok) throw new Error('artifact_open_failed');
    return response.json();
  }

  function renderArtifactList() {
    if (!artifactListEl) return;
    artifactListEl.innerHTML = '';

    if (!artifactCache.length) {
      artifactListEl.textContent = 'Нет сохранённых файлов в этом разделе.';
      return;
    }

    artifactCache.forEach(function (item) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'artifact-item' + (selectedArtifact && selectedArtifact.file === item.file ? ' is-active' : '');
      btn.textContent = item.file;
      btn.title = item.updatedAt || item.file;
      btn.addEventListener('click', function () {
        openArtifact(item.file);
      });
      artifactListEl.appendChild(btn);
    });
  }

  async function refreshArtifacts() {
    if (!artifactBucketSelect) return;
    const bucket = artifactBucketSelect.value || 'notes';
    try {
      const payload = await fetchArtifacts(bucket);
      artifactCache = payload.items || [];
      if (!artifactCache.some(function (x) { return selectedArtifact && x.file === selectedArtifact.file; })) {
        selectedArtifact = null;
      }
      renderArtifactList();
    } catch (_err) {
      artifactCache = [];
      selectedArtifact = null;
      if (artifactListEl) artifactListEl.textContent = 'Не удалось загрузить список artifacts.';
    }
  }

  async function openArtifact(file) {
    if (!artifactBucketSelect) return;
    const bucket = artifactBucketSelect.value || 'notes';
    try {
      const payload = await fetchArtifact(bucket, file);
      selectedArtifact = { bucket: bucket, file: file, content: payload.content || '' };
      artifactPreviewEl.textContent = selectedArtifact.content || '(пусто)';
      renderArtifactList();
    } catch (_err) {
      selectedArtifact = null;
      artifactPreviewEl.textContent = 'Не удалось открыть artifact.';
      renderArtifactList();
    }
  }

  setStatus('booting', '#c9a468');
  term.open(terminalEl);
  scheduleFitSequence();
  term.focus();

  ws.addEventListener('open', function () {
    setStatus('ws open', '#c9a468');
    scheduleFitSequence();
  });

  ws.addEventListener('message', function (event) {
    try {
      const msg = JSON.parse(event.data);
      if (msg.type === 'ready') {
        setStatus('attached', '#89ba91');
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
    setStatus('closed', '#cc7777');
    term.writeln('\r\n\x1b[31m[closed]\x1b[0m websocket closed');
  });

  ws.addEventListener('error', function () {
    setStatus('ws error', '#cc7777');
    term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m websocket error');
  });

  term.onData(function (data) {
    sendInput(data, false);
  });

  document.querySelectorAll('[data-insert], [data-command], [data-send]').forEach(function (button) {
    button.addEventListener('mousedown', function (evt) {
      evt.preventDefault();
    });
    button.addEventListener('touchstart', function (evt) {
      evt.preventDefault();
    }, { passive: false });

    button.addEventListener('click', function () {
      const insert = button.getAttribute('data-insert');
      const command = button.getAttribute('data-command');
      const legacy = button.getAttribute('data-send');

      if (insert) {
        insertByContext(insert);
        return;
      }
      if (command) {
        const withEnter = button.getAttribute('data-enter') === '1';
        if (withEnter) sendCommand(command);
        else sendInput(command, false);
        return;
      }
      if (legacy) {
        sendInput(legacy.replace(/\\r/g, '\r').replace(/\\n/g, '\n'), false);
      }
    });
  });

  menuTabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      activatePane(tab.getAttribute('data-pane'), true);
    });
  });

  if (backButton) {
    backButton.addEventListener('click', softBack);
  }

  if (paletteInsertBtn) {
    paletteInsertBtn.addEventListener('click', function () {
      insertAtCursor(formBuffer, paletteSelect.value || '');
    });
  }

  if (paletteRunBtn) {
    paletteRunBtn.addEventListener('click', function () {
      sendCommand(paletteSelect.value || '');
    });
  }

  if (bufferSendLineBtn) {
    bufferSendLineBtn.addEventListener('click', function () {
      const line = currentLineFromTextarea(formBuffer);
      if (line) sendCommand(line);
    });
  }

  if (bufferSendSelectionBtn) {
    bufferSendSelectionBtn.addEventListener('click', function () {
      const text = (formBuffer.value || '').slice(formBuffer.selectionStart || 0, formBuffer.selectionEnd || 0).trim();
      if (text) {
        sendCommandsFromText(text);
      } else {
        const line = currentLineFromTextarea(formBuffer);
        if (line) sendCommand(line);
      }
    });
  }

  if (bufferSendAllBtn) {
    bufferSendAllBtn.addEventListener('click', function () {
      sendCommandsFromText(formBuffer.value || '');
    });
  }

  if (bufferClearBtn) {
    bufferClearBtn.addEventListener('click', function () {
      formBuffer.value = '';
      formBuffer.focus();
    });
  }

  if (blockSaveBtn) {
    blockSaveBtn.addEventListener('click', function () {
      const name = String(blockNameInput.value || '').trim();
      const selected = (formBuffer.value || '').slice(formBuffer.selectionStart || 0, formBuffer.selectionEnd || 0).trim();
      const source = selected || (formBuffer.value || '').trim();
      const payload = choosePayloadForBlock(source);

      if (!name || !payload) {
        term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m блок: нужно имя и форма в буфере');
        return;
      }

      sendCommand('(блок ' + name + ' ' + payload + ')');
    });
  }

  if (blockInsertBtn) {
    blockInsertBtn.addEventListener('click', function () {
      const name = String(blockNameInput.value || '').trim();
      if (!name) {
        term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m укажи имя блока');
        return;
      }
      sendCommand('(вставить-блок ' + name + ')');
    });
  }

  if (schemeRunBtn) {
    schemeRunBtn.addEventListener('click', function () {
      const concept = String(schemeConceptInput.value || '').trim();
      if (!concept) return;
      sendCommand('(схема ' + concept + ')');
    });
  }

  if (schemeViewBtn) {
    schemeViewBtn.addEventListener('click', function () {
      const concept = String(schemeConceptInput.value || '').trim();
      if (!concept) return;
      sendCommand('(вид схема ' + concept + ')');
    });
  }

  if (schemeSaveBtn) {
    schemeSaveBtn.addEventListener('click', function () {
      const concept = String(schemeConceptInput.value || '').trim() || 'scheme-v0';
      const safe = concept.replace(/\s+/g, '-');
      sendCommand('(сохранить-схему ' + safe + ')');
      refreshArtifacts();
    });
  }

  if (artifactRefreshBtn) {
    artifactRefreshBtn.addEventListener('click', refreshArtifacts);
  }

  if (artifactBucketSelect) {
    artifactBucketSelect.addEventListener('change', function () {
      selectedArtifact = null;
      artifactPreviewEl.textContent = 'Выбери артефакт, чтобы открыть его здесь.';
      refreshArtifacts();
    });
  }

  if (artifactInsertBtn) {
    artifactInsertBtn.addEventListener('click', function () {
      if (!selectedArtifact || !selectedArtifact.content) return;
      insertAtCursor(formBuffer, selectedArtifact.content + '\n');
      activatePane('buffer', true);
    });
  }

  if (artifactRunBtn) {
    artifactRunBtn.addEventListener('click', function () {
      if (!selectedArtifact || !selectedArtifact.content) return;
      const forms = extractForms(selectedArtifact.content);
      if (!forms.length) {
        term.writeln('\r\n\x1b[33m[заметка]\x1b[0m в выбранном artifact не найдено строк-форм');
        return;
      }
      forms.forEach(sendCommand);
    });
  }

  terminalEl.addEventListener('click', function () {
    term.focus();
    stabilizeViewport();
  });

  window.addEventListener('resize', scheduleFitSequence);
  window.addEventListener('orientationchange', function () {
    setTimeout(scheduleFitSequence, 40);
  });

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

  activatePane('console', false);
  refreshArtifacts();
})();
