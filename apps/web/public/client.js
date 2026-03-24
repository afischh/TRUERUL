(function () {
  const terminalEl = document.getElementById('terminal');
  const statusEl = document.getElementById('connection-status');
  const statusRuntimeEl = document.getElementById('status-runtime');
  const statusLanguageEl = document.getElementById('status-language');
  const statusOutputModeEl = document.getElementById('status-output-mode');
  const statusVoiceEl = document.getElementById('status-voice');
  const statusActivePaneEl = document.getElementById('status-active-pane');
  const statusArtifactEl = document.getElementById('status-artifact');
  const menuContextEl = document.getElementById('menu-context');

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
  const artifactOpenViewBtn = document.getElementById('artifact-open-view');

  const bufferSendLineBtn = document.getElementById('buffer-send-line');
  const bufferSendSelectionBtn = document.getElementById('buffer-send-selection');
  const bufferSendAllBtn = document.getElementById('buffer-send-all');
  const bufferClearBtn = document.getElementById('buffer-clear');
  const blockSaveBtn = document.getElementById('block-save');
  const blockInsertBtn = document.getElementById('block-insert');
  const blockRunBtn = document.getElementById('block-run');
  const completionInput = document.getElementById('completion-input');
  const completionApplyBtn = document.getElementById('completion-apply');
  const completionInsertBtn = document.getElementById('completion-insert');
  const completionSuggestionsEl = document.getElementById('completion-suggestions');

  const schemeRunBtn = document.getElementById('scheme-run');
  const schemeViewBtn = document.getElementById('scheme-view');
  const schemeSaveBtn = document.getElementById('scheme-save');

  const inspectorTitleEl = document.getElementById('inspector-title');
  const inspectorBodyEl = document.getElementById('inspector-body');
  const inspectorInsertBtn = document.getElementById('inspector-insert');
  const inspectorRunBtn = document.getElementById('inspector-run');
  const inspectorOpenViewBtn = document.getElementById('inspector-open-view');
  const inspectorBlockNameInput = document.getElementById('inspector-block-name');
  const inspectorSaveBlockBtn = document.getElementById('inspector-save-block');
  const libraryCards = document.querySelectorAll('.lib-card');

  const toolRunLineBtn = document.getElementById('tool-run-line');
  const toolRunSelectionBtn = document.getElementById('tool-run-selection');
  const toolRunBufferBtn = document.getElementById('tool-run-buffer');
  const toolHistoryBtn = document.getElementById('tool-history');
  const toolSaveBlockBtn = document.getElementById('tool-save-block');
  const toolSchemeBtn = document.getElementById('tool-scheme');
  const toolHelpBtn = document.getElementById('tool-help');
  const modeCleanBtn = document.getElementById('mode-clean');
  const modeVerboseBtn = document.getElementById('mode-verbose');

  const leftInsertBlockBtn = document.getElementById('left-insert-block');
  const leftSaveBlockBtn = document.getElementById('left-save-block');
  const leftListBlocksBtn = document.getElementById('left-list-blocks');
  const leftOpenViewsBtn = document.getElementById('left-open-views');

  const bottomOutputLogEl = document.getElementById('bottom-output-log');
  const bottomBufferPreviewEl = document.getElementById('bottom-buffer-preview');
  const bottomArtifactPreviewEl = document.getElementById('bottom-artifact-preview');
  const bottomTabs = document.querySelectorAll('.bottom-tab[data-bottom-pane]');
  const bottomContents = document.querySelectorAll('.bottom-content[data-bottom-content]');

  const paneLabels = {
    file: 'Файл',
    edit: 'Правка',
    view: 'Вид',
    console: 'Консоль',
    library: 'Библиотека',
    schemes: 'Схемы',
    history: 'История',
    settings: 'Настройки',
    help: 'Справка'
  };

  let activePane = 'console';
  const paneHistory = ['console'];
  const recentCommands = [];
  let bottomLogLines = ['Готово.'];

  let artifactCache = [];
  let selectedArtifact = null;
  let lastCompletionValue = '';

  const completionTemplates = [
    '(сущность имя :тип тип)',
    '(связь левая отношение правая)',
    '(состояние цель состояние)',
    '(запрос (связь? субъект отношение X))',
    '(запрос (сущность? имя :тип _))',
    '(запрос (состояние? цель X))',
    '(фигура имя)',
    '(категория имя)',
    '(дихотомия левая правая)',
    '(напряжение левая правая)',
    '(схема понятие)',
    '(блок имя (сущность узел :тип точка))',
    '(блоки)',
    '(вставить-блок имя)',
    '(выполнить-блок имя)',
    '(сохранить имя)',
    '(сохранить-вид имя)',
    '(сохранить-таблицу имя)',
    '(сохранить-схему имя)',
    '(слои)',
    '(ритм)',
    '(канон)',
    '(голоса)',
    '(голос синтез)',
    '(режим :голос синтез)',
    '(применить-голос синтез (схема понятие))',
    '(гипотеза h1 (связь субъект отношение объект))',
    '(спор тезис антитезис)',
    '(заметка рабочая-заметка)',
    '(вывод текущий-контур)',
    '(lib-индекс)',
    '(lib-список :domain logic :logic-mode classical :cost 3)',
    '(lib-подобрать :domain foundations :input-kind type-judgement)',
    '(ассист "если данные противоречат" :role parse-assist)',
    '(оператор "если данные противоречат" :domain logic)',
    '(история)',
    '(назад)',
    '(повторить)',
    '(помощь)'
  ];

  let selectedInspector = {
    title: 'Карточка не выбрана',
    body: 'Выбери элемент в левой панели, чтобы увидеть детали и выполнить/вставить форму.',
    command: '',
    insert: ''
  };

  function setStatus(text, color) {
    if (!statusEl) return;
    statusEl.textContent = text;
    if (color) statusEl.style.color = color;
  }

  function setRuntimeStatus(runtime) {
    if (!statusRuntimeEl) return;
    statusRuntimeEl.textContent = 'runtime: ' + (runtime || '-');
  }

  function setLanguageStatus(lang) {
    if (!statusLanguageEl) return;
    statusLanguageEl.textContent = 'lang: ' + (lang || 'RU');
  }

  function setOutputMode(mode) {
    const normalized = mode || 'clean';
    if (statusOutputModeEl) statusOutputModeEl.textContent = 'output: ' + normalized;
    if (modeCleanBtn) modeCleanBtn.classList.toggle('is-active', normalized === 'clean');
    if (modeVerboseBtn) modeVerboseBtn.classList.toggle('is-active', normalized === 'verbose');
  }

  function setVoiceStatus(voice) {
    if (!statusVoiceEl) return;
    statusVoiceEl.textContent = 'voice: ' + (voice || 'синтез');
  }

  function setActivePaneStatus(pane) {
    if (statusActivePaneEl) statusActivePaneEl.textContent = 'pane: ' + (pane || '-');
    if (menuContextEl) menuContextEl.textContent = 'Контекст: ' + (paneLabels[pane] || pane || '-');
  }

  function setArtifactStatus(text) {
    if (!statusArtifactEl) return;
    statusArtifactEl.textContent = 'artifact: ' + (text || '-');
  }

  function pushBottomLog(line) {
    const value = String(line || '').trim();
    if (!value) return;
    bottomLogLines.push(value);
    if (bottomLogLines.length > 120) bottomLogLines = bottomLogLines.slice(bottomLogLines.length - 120);
    if (bottomOutputLogEl) bottomOutputLogEl.textContent = bottomLogLines.join('\n');
  }

  function escapeHtml(text) {
    return String(text || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function renderRecentCommands() {
    if (!recentCommandsEl) return;
    if (!recentCommands.length) {
      recentCommandsEl.textContent = 'Пока пусто.';
      return;
    }
    recentCommandsEl.innerHTML = recentCommands
      .map(function (item, index) {
        const escaped = escapeHtml(item);
        return '<div class="recent-entry">' +
          '<span>' + (index + 1) + '. ' + escaped + '</span> ' +
          '<button type="button" class="recent-action" data-recent-action="run" data-recent-index="' + index + '">run</button> ' +
          '<button type="button" class="recent-action" data-recent-action="insert" data-recent-index="' + index + '">insert</button>' +
          '</div>';
      })
      .join('');
  }

  function rememberCommand(command) {
    if (!command) return;
    const normalized = command.trim();
    if (!normalized) return;
    if (recentCommands[0] !== normalized) {
      recentCommands.unshift(normalized);
      if (recentCommands.length > 14) recentCommands.pop();
    }
    renderRecentCommands();
  }

  function activatePane(name, pushHistory) {
    activePane = name;
    menuTabs.forEach(function (tab) {
      tab.classList.toggle('is-active', tab.getAttribute('data-pane') === name);
    });
    paneNodes.forEach(function (pane) {
      pane.classList.toggle('is-active', pane.getAttribute('data-pane-content') === name);
    });

    if (pushHistory && paneHistory[paneHistory.length - 1] !== name) {
      paneHistory.push(name);
    }

    if (name === 'view') refreshArtifacts();
    if (name === 'edit' && formBuffer) formBuffer.focus();

    setActivePaneStatus(name);
  }

  function activateBottomPane(name) {
    bottomTabs.forEach(function (tab) {
      tab.classList.toggle('is-active', tab.getAttribute('data-bottom-pane') === name);
    });
    bottomContents.forEach(function (pane) {
      pane.classList.toggle('is-active', pane.getAttribute('data-bottom-content') === name);
    });
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
    refreshBufferPreview();
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

  function templateHead(template) {
    const match = String(template || '').match(/^\(([^\s()]+)/);
    return match ? match[1].toLowerCase() : '';
  }

  function findCompletionMatches(prefix) {
    const normalized = String(prefix || '')
      .trim()
      .replace(/^\(/, '')
      .toLowerCase();
    if (!normalized) return completionTemplates.slice(0, 12);
    return completionTemplates.filter(function (template) {
      const head = templateHead(template);
      return head.startsWith(normalized) || template.toLowerCase().indexOf(normalized) >= 0;
    });
  }

  function renderCompletionSuggestions(prefix) {
    if (!completionSuggestionsEl) return [];
    const matches = findCompletionMatches(prefix);
    completionSuggestionsEl.innerHTML = '';
    if (!matches.length) {
      completionSuggestionsEl.textContent = 'Совпадений нет.';
      lastCompletionValue = '';
      return [];
    }
    lastCompletionValue = matches[0];
    matches.slice(0, 10).forEach(function (template) {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'completion-item';
      button.textContent = template;
      button.setAttribute('data-template', template);
      completionSuggestionsEl.appendChild(button);
    });
    return matches;
  }

  function applyCompletionInsert(template) {
    if (!template) return;
    insertAtCursor(formBuffer, template + '\n');
    activatePane('edit', true);
    pushBottomLog('[completion] insert ' + templateHead(template));
  }

  function completeHeadInBuffer() {
    if (!formBuffer) return false;
    const cursor = formBuffer.selectionStart || 0;
    const text = formBuffer.value || '';
    const lineStart = text.lastIndexOf('\n', Math.max(0, cursor - 1)) + 1;
    const beforeCursor = text.slice(lineStart, cursor);
    const match = beforeCursor.match(/\(([^\s()]*)$/);
    if (!match) return false;
    const prefix = match[1];
    if (!prefix) return false;
    const matches = findCompletionMatches(prefix);
    if (!matches.length) return false;
    if (completionInput) completionInput.value = prefix;
    renderCompletionSuggestions(prefix);
    if (matches.length !== 1) return true;
    const chosen = matches[0];
    const head = templateHead(chosen);
    const replacement = '(' + head + ' ';
    const replaceStart = cursor - prefix.length - 1;
    formBuffer.value = text.slice(0, replaceStart) + replacement + text.slice(cursor);
    const newCursor = replaceStart + replacement.length;
    formBuffer.selectionStart = newCursor;
    formBuffer.selectionEnd = newCursor;
    refreshBufferPreview();
    pushBottomLog('[completion] head -> ' + head);
    return true;
  }

  function refreshBufferPreview() {
    if (!bottomBufferPreviewEl || !formBuffer) return;
    const value = String(formBuffer.value || '').trim();
    bottomBufferPreviewEl.textContent = value || 'Буфер пока пуст.';
  }

  function setInspector(data) {
    selectedInspector = {
      title: data.title || 'Карточка',
      body: data.body || '',
      command: data.command || '',
      insert: data.insert || data.command || ''
    };
    if (inspectorTitleEl) inspectorTitleEl.textContent = selectedInspector.title;
    if (inspectorBodyEl) inspectorBodyEl.textContent = selectedInspector.body;
  }

  if (!window.Terminal) {
    setStatus('xterm missing', '#8f2d2d');
    terminalEl.textContent = 'TRUERUL boot error: xterm.js did not load.';
    return;
  }

  const TerminalCtor = window.Terminal;
  const FitAddonCtor = window.FitAddon && (window.FitAddon.FitAddon || window.FitAddon);

  const term = new TerminalCtor({
    cursorBlink: true,
    fontFamily: 'Iosevka Term, Consolas, Liberation Mono, monospace',
    fontSize: 14,
    lineHeight: 1.2,
    convertEol: true,
    scrollback: 5000,
    theme: {
      background: '#09131e',
      foreground: '#d6dce3',
      cursor: '#9fb5cc',
      black: '#09131e',
      red: '#d08c8c',
      green: '#97c3a6',
      yellow: '#d6be8f',
      blue: '#8faecc',
      magenta: '#b8a0cc',
      cyan: '#98bdcb',
      white: '#d6dce3',
      brightBlack: '#6c7784',
      brightRed: '#df9f9f',
      brightGreen: '#a9cfb6',
      brightYellow: '#e1ca9a',
      brightBlue: '#9fc0df',
      brightMagenta: '#c7b1d9',
      brightCyan: '#a7cad8',
      brightWhite: '#f2f5f8'
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
    setTimeout(fitAndResize, 24);
    setTimeout(fitAndResize, 90);
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
    if (/\(режим\b[^\)]*:вывод\s+clean/i.test(cmd)) setOutputMode('clean');
    if (/\(режим\b[^\)]*:вывод\s+verbose/i.test(cmd)) setOutputMode('verbose');
    if (/\(режим\b[^\)]*:язык\s+ru/i.test(cmd)) setLanguageStatus('RU');
    if (/\(режим\b[^\)]*:язык\s+en/i.test(cmd)) setLanguageStatus('EN');
    const voiceMatch = cmd.match(/\(режим\b[^\)]*:голос\s+([^\s\)]+)/i);
    if (voiceMatch && voiceMatch[1]) setVoiceStatus(voiceMatch[1].toLowerCase());
    const directVoiceMatch = cmd.match(/^\(голос\s+([^\s\)]+)/i);
    if (directVoiceMatch && directVoiceMatch[1]) setVoiceStatus(directVoiceMatch[1].toLowerCase());
    rememberCommand(cmd);
    pushBottomLog('> ' + cmd);
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
      if (!selectedArtifact) {
        if (artifactPreviewEl) artifactPreviewEl.textContent = 'Выбери артефакт, чтобы открыть его здесь.';
        if (bottomArtifactPreviewEl) bottomArtifactPreviewEl.textContent = 'Artifact пока не выбран.';
        setArtifactStatus('-');
      }
      pushBottomLog('[artifacts] refreshed bucket=' + bucket + ' items=' + artifactCache.length);
    } catch (_err) {
      artifactCache = [];
      selectedArtifact = null;
      if (artifactListEl) artifactListEl.textContent = 'Не удалось загрузить список artifacts.';
      if (bottomArtifactPreviewEl) bottomArtifactPreviewEl.textContent = 'Не удалось загрузить список артефактов.';
      pushBottomLog('[ошибка] artifacts list failed');
    }
  }

  async function openArtifact(file) {
    if (!artifactBucketSelect) return;
    const bucket = artifactBucketSelect.value || 'notes';
    try {
      const payload = await fetchArtifact(bucket, file);
      selectedArtifact = { bucket: bucket, file: file, content: payload.content || '' };
      if (artifactPreviewEl) artifactPreviewEl.textContent = selectedArtifact.content || '(пусто)';
      if (bottomArtifactPreviewEl) bottomArtifactPreviewEl.textContent = selectedArtifact.content || '(пусто)';
      renderArtifactList();
      setArtifactStatus(bucket + '/' + file);
      setInspector({
        title: 'Артефакт: ' + file,
        body: 'bucket: ' + bucket + '\n\n' + (selectedArtifact.content || '(пусто)'),
        command: '',
        insert: selectedArtifact.content || ''
      });
      pushBottomLog('[artifact] opened ' + bucket + '/' + file);
    } catch (_err) {
      selectedArtifact = null;
      if (artifactPreviewEl) artifactPreviewEl.textContent = 'Не удалось открыть artifact.';
      if (bottomArtifactPreviewEl) bottomArtifactPreviewEl.textContent = 'Не удалось открыть artifact.';
      renderArtifactList();
      setArtifactStatus('-');
      pushBottomLog('[ошибка] artifact open failed');
    }
  }

  setStatus('booting', '#8a5c1f');
  setRuntimeStatus('-');
  setLanguageStatus('RU');
  setOutputMode('clean');
  setVoiceStatus('синтез');
  setActivePaneStatus('console');
  setArtifactStatus('-');

  term.open(terminalEl);
  scheduleFitSequence();
  term.focus();

  ws.addEventListener('open', function () {
    setStatus('ws open', '#8a5c1f');
    pushBottomLog('[ws] open');
    scheduleFitSequence();
  });

  ws.addEventListener('message', function (event) {
    try {
      const msg = JSON.parse(event.data);
      if (msg.type === 'ready') {
        setStatus('attached', '#2f6b41');
        setRuntimeStatus(msg.runtime || '-');
        pushBottomLog('[ws] attached runtime=' + (msg.runtime || '-'));
        scheduleFitSequence();
        return;
      }
      if (msg.type === 'data' && typeof msg.data === 'string') {
        term.write(msg.data);
        stabilizeViewport();
      }
    } catch (_err) {
      term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m malformed server frame');
      pushBottomLog('[ошибка] malformed server frame');
      stabilizeViewport();
    }
  });

  ws.addEventListener('close', function () {
    setStatus('closed', '#8f2d2d');
    term.writeln('\r\n\x1b[31m[closed]\x1b[0m websocket closed');
    pushBottomLog('[ws] closed');
  });

  ws.addEventListener('error', function () {
    setStatus('ws error', '#8f2d2d');
    term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m websocket error');
    pushBottomLog('[ошибка] websocket error');
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
        if (command.indexOf('(режим :вывод clean)') === 0) setOutputMode('clean');
        if (command.indexOf('(режим :вывод verbose)') === 0) setOutputMode('verbose');
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

  bottomTabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      activateBottomPane(tab.getAttribute('data-bottom-pane'));
    });
  });

  if (backButton) backButton.addEventListener('click', softBack);

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

  if (completionApplyBtn) {
    completionApplyBtn.addEventListener('click', function () {
      const prefix = completionInput ? completionInput.value : '';
      renderCompletionSuggestions(prefix);
    });
  }

  if (completionInsertBtn) {
    completionInsertBtn.addEventListener('click', function () {
      const prefix = completionInput ? completionInput.value : '';
      const matches = renderCompletionSuggestions(prefix);
      if (matches.length) {
        applyCompletionInsert(matches[0]);
        return;
      }
      if (lastCompletionValue) applyCompletionInsert(lastCompletionValue);
    });
  }

  if (completionInput) {
    completionInput.addEventListener('input', function () {
      renderCompletionSuggestions(completionInput.value || '');
    });
    completionInput.addEventListener('keydown', function (event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        const matches = renderCompletionSuggestions(completionInput.value || '');
        if (matches.length) applyCompletionInsert(matches[0]);
      }
    });
  }

  if (completionSuggestionsEl) {
    completionSuggestionsEl.addEventListener('click', function (event) {
      const button = event.target.closest('button[data-template]');
      if (!button) return;
      const template = button.getAttribute('data-template');
      if (!template) return;
      lastCompletionValue = template;
      applyCompletionInsert(template);
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
      if (text) sendCommandsFromText(text);
      else {
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
      refreshBufferPreview();
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
        pushBottomLog('[ошибка] блок: нужно имя и форма в буфере');
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
        pushBottomLog('[ошибка] укажи имя блока');
        return;
      }
      sendCommand('(вставить-блок ' + name + ')');
    });
  }

  if (blockRunBtn) {
    blockRunBtn.addEventListener('click', function () {
      const name = String(blockNameInput.value || '').trim();
      if (!name) {
        term.writeln('\r\n\x1b[31m[ошибка]\x1b[0m укажи имя блока');
        pushBottomLog('[ошибка] укажи имя блока');
        return;
      }
      sendCommand('(выполнить-блок ' + name + ')');
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
      const concept = String(schemeConceptInput.value || '').trim() || 'scheme-v1';
      const safe = concept.replace(/\s+/g, '-');
      sendCommand('(сохранить-схему ' + safe + ')');
      refreshArtifacts();
    });
  }

  if (artifactRefreshBtn) artifactRefreshBtn.addEventListener('click', refreshArtifacts);

  if (artifactBucketSelect) {
    artifactBucketSelect.addEventListener('change', function () {
      selectedArtifact = null;
      if (artifactPreviewEl) artifactPreviewEl.textContent = 'Выбери артефакт, чтобы открыть его здесь.';
      if (bottomArtifactPreviewEl) bottomArtifactPreviewEl.textContent = 'Artifact пока не выбран.';
      setArtifactStatus('-');
      refreshArtifacts();
    });
  }

  if (artifactInsertBtn) {
    artifactInsertBtn.addEventListener('click', function () {
      if (!selectedArtifact || !selectedArtifact.content) return;
      insertAtCursor(formBuffer, selectedArtifact.content + '\n');
      activatePane('edit', true);
    });
  }

  if (artifactRunBtn) {
    artifactRunBtn.addEventListener('click', function () {
      if (!selectedArtifact || !selectedArtifact.content) return;
      const forms = extractForms(selectedArtifact.content);
      if (!forms.length) {
        term.writeln('\r\n\x1b[33m[заметка]\x1b[0m в выбранном artifact не найдено строк-форм');
        pushBottomLog('[заметка] в выбранном artifact не найдено строк-форм');
        return;
      }
      forms.forEach(sendCommand);
    });
  }

  if (artifactOpenViewBtn) {
    artifactOpenViewBtn.addEventListener('click', function () {
      activateBottomPane('artifact');
      activatePane('view', true);
    });
  }

  if (toolRunLineBtn) toolRunLineBtn.addEventListener('click', function () { if (bufferSendLineBtn) bufferSendLineBtn.click(); });
  if (toolRunSelectionBtn) toolRunSelectionBtn.addEventListener('click', function () { if (bufferSendSelectionBtn) bufferSendSelectionBtn.click(); });
  if (toolRunBufferBtn) toolRunBufferBtn.addEventListener('click', function () { if (bufferSendAllBtn) bufferSendAllBtn.click(); });
  if (toolHistoryBtn) toolHistoryBtn.addEventListener('click', function () { activatePane('history', true); });
  if (toolSaveBlockBtn) toolSaveBlockBtn.addEventListener('click', function () { if (blockSaveBtn) blockSaveBtn.click(); });

  if (toolSchemeBtn) {
    toolSchemeBtn.addEventListener('click', function () {
      activatePane('schemes', true);
      const concept = String(schemeConceptInput && schemeConceptInput.value || '').trim();
      if (concept) sendCommand('(схема ' + concept + ')');
    });
  }

  if (toolHelpBtn) toolHelpBtn.addEventListener('click', function () { activatePane('help', true); });
  if (modeCleanBtn) modeCleanBtn.addEventListener('click', function () { setOutputMode('clean'); });
  if (modeVerboseBtn) modeVerboseBtn.addEventListener('click', function () { setOutputMode('verbose'); });

  if (leftInsertBlockBtn) {
    leftInsertBlockBtn.addEventListener('click', function () {
      activatePane('edit', true);
      if (blockNameInput) blockNameInput.focus();
    });
  }

  if (leftSaveBlockBtn) {
    leftSaveBlockBtn.addEventListener('click', function () {
      activatePane('edit', true);
      if (blockSaveBtn) blockSaveBtn.click();
    });
  }

  if (leftListBlocksBtn) {
    leftListBlocksBtn.addEventListener('click', function () {
      sendCommand('(блоки)');
      activatePane('history', true);
    });
  }

  if (leftOpenViewsBtn) {
    leftOpenViewsBtn.addEventListener('click', function () {
      activatePane('view', true);
      refreshArtifacts();
    });
  }

  libraryCards.forEach(function (card) {
    card.addEventListener('click', function () {
      libraryCards.forEach(function (node) { node.classList.remove('is-selected'); });
      card.classList.add('is-selected');
      setInspector({
        title: card.getAttribute('data-inspect-title') || 'Карточка',
        body: card.getAttribute('data-inspect-body') || '',
        command: card.getAttribute('data-inspect-command') || '',
        insert: card.getAttribute('data-inspect-insert') || card.getAttribute('data-inspect-command') || ''
      });
      activatePane('library', true);
    });
  });

  if (inspectorInsertBtn) {
    inspectorInsertBtn.addEventListener('click', function () {
      if (!selectedInspector.insert) return;
      insertAtCursor(formBuffer, selectedInspector.insert + '\n');
      activatePane('edit', true);
      pushBottomLog('[library] insert from inspector');
    });
  }

  if (inspectorRunBtn) {
    inspectorRunBtn.addEventListener('click', function () {
      if (!selectedInspector.command) return;
      sendCommand(selectedInspector.command);
      pushBottomLog('[library] run from inspector');
    });
  }

  if (inspectorOpenViewBtn) {
    inspectorOpenViewBtn.addEventListener('click', function () {
      if (selectedArtifact && selectedArtifact.content) {
        activatePane('view', true);
        activateBottomPane('artifact');
        return;
      }
      activatePane('library', true);
      activateBottomPane('buffer');
    });
  }

  if (inspectorSaveBlockBtn) {
    inspectorSaveBlockBtn.addEventListener('click', function () {
      const name = String(inspectorBlockNameInput && inspectorBlockNameInput.value || '').trim();
      const candidate = String(selectedInspector.command || selectedInspector.insert || '').trim();
      const payload = choosePayloadForBlock(candidate) || candidate;
      if (!name || !payload) {
        pushBottomLog('[ошибка] инспектор: нужно имя блока и форма');
        return;
      }
      sendCommand('(блок ' + name + ' ' + payload + ')');
      if (blockNameInput) blockNameInput.value = name;
      if (artifactBucketSelect) artifactBucketSelect.value = 'blocks';
      refreshArtifacts();
    });
  }

  if (recentCommandsEl) {
    recentCommandsEl.addEventListener('click', function (event) {
      const button = event.target.closest('button[data-recent-action]');
      if (!button) return;
      const action = button.getAttribute('data-recent-action');
      const index = Number(button.getAttribute('data-recent-index'));
      const cmd = recentCommands[index];
      if (!cmd) return;
      if (action === 'run') sendCommand(cmd);
      if (action === 'insert') {
        insertAtCursor(formBuffer, cmd + '\n');
        activatePane('edit', true);
      }
    });
  }

  terminalEl.addEventListener('click', function () {
    term.focus();
    stabilizeViewport();
  });

  if (formBuffer) {
    formBuffer.addEventListener('input', refreshBufferPreview);
    formBuffer.addEventListener('keydown', function (event) {
      if (event.key === 'Tab') {
        if (completeHeadInBuffer()) {
          event.preventDefault();
          return;
        }
      }
      if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
        event.preventDefault();
        if (bufferSendAllBtn) bufferSendAllBtn.click();
      }
    });
  }

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

  setInspector(selectedInspector);
  renderRecentCommands();
  renderCompletionSuggestions('');
  activatePane('console', false);
  activateBottomPane('log');
  refreshBufferPreview();
  refreshArtifacts();
})();
