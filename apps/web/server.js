import express from 'express';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs/promises';
import { WebSocketServer } from 'ws';
import pty from 'node-pty';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '../..');
const publicDir = path.join(__dirname, 'public');
const nodeModulesDir = path.join(rootDir, 'node_modules');
const xtermDir = path.join(nodeModulesDir, '@xterm', 'xterm');

const PORT = Number(process.env.TRUERUL_WEB_PORT || 4173);
const DEFAULT_RUNTIME = process.env.TRUERUL_RUNTIME || 'js';
const artifactsRootDir = path.join(rootDir, 'lisp', 'artifacts');
const artifactBuckets = new Set(['notes', 'views', 'tables', 'schemes', 'blocks']);

function assertArtifactBucket(bucket) {
  if (!artifactBuckets.has(bucket)) {
    throw new Error('invalid_bucket');
  }
  return bucket;
}

function artifactBucketDir(bucket) {
  return path.join(artifactsRootDir, assertArtifactBucket(bucket));
}

async function listArtifacts(bucket) {
  const bucketDir = artifactBucketDir(bucket);
  let entries = [];
  try {
    entries = await fs.readdir(bucketDir, { withFileTypes: true });
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return [];
    }
    throw error;
  }

  const files = entries.filter((entry) => entry.isFile()).map((entry) => entry.name);
  const withStats = await Promise.all(files.map(async (file) => {
    const filePath = path.join(bucketDir, file);
    const stat = await fs.stat(filePath);
    return {
      file,
      size: stat.size,
      mtimeMs: stat.mtimeMs,
      updatedAt: stat.mtime.toISOString()
    };
  }));

  withStats.sort((a, b) => b.mtimeMs - a.mtimeMs);
  return withStats;
}

const app = express();
app.use(express.json({ limit: '256kb' }));
app.use(express.static(publicDir));
app.use('/vendor/xterm', express.static(path.join(xtermDir, 'lib')));
app.use('/vendor/xterm/css', express.static(path.join(xtermDir, 'css')));
app.use('/vendor/xterm-addon-fit', express.static(path.join(nodeModulesDir, '@xterm', 'addon-fit', 'lib')));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'truerul-web', port: PORT, runtime: DEFAULT_RUNTIME });
});

app.get('/api/artifacts', async (req, res) => {
  try {
    const bucket = assertArtifactBucket(String(req.query.bucket || 'notes'));
    const items = await listArtifacts(bucket);
    res.json({ ok: true, bucket, items });
  } catch (error) {
    if (error && error.message === 'invalid_bucket') {
      res.status(400).json({ ok: false, error: 'invalid_bucket' });
      return;
    }
    res.status(500).json({ ok: false, error: 'artifact_list_failed' });
  }
});

app.get('/api/artifacts/:bucket/:file', async (req, res) => {
  try {
    const bucket = assertArtifactBucket(String(req.params.bucket || ''));
    const requested = String(req.params.file || '');
    const safeFile = path.basename(requested);
    if (!safeFile || safeFile !== requested) {
      res.status(400).json({ ok: false, error: 'invalid_file' });
      return;
    }

    const filePath = path.join(artifactBucketDir(bucket), safeFile);
    const content = await fs.readFile(filePath, 'utf8');
    res.json({ ok: true, bucket, file: safeFile, content });
  } catch (error) {
    if (error && error.message === 'invalid_bucket') {
      res.status(400).json({ ok: false, error: 'invalid_bucket' });
      return;
    }
    if (error && error.code === 'ENOENT') {
      res.status(404).json({ ok: false, error: 'artifact_not_found' });
      return;
    }
    res.status(500).json({ ok: false, error: 'artifact_read_failed' });
  }
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function runtimeProcess() {
  if (DEFAULT_RUNTIME === 'lisp') {
    const replPath = path.join(rootDir, 'lisp', 'scripts', 'run_truerul.sh');
    return { file: 'bash', args: [replPath] };
  }
  const replPath = path.join(rootDir, 'scripts', 'dummy_repl.js');
  return { file: process.execPath, args: [replPath] };
}

wss.on('connection', (ws) => {
  const runtime = runtimeProcess();
  const term = pty.spawn(runtime.file, runtime.args, {
    name: 'xterm-256color',
    cols: 80,
    rows: 24,
    cwd: rootDir,
    env: {
      ...process.env,
      TERM: 'xterm-256color',
      COLORTERM: 'truecolor'
    }
  });

  const onData = (data) => {
    if (ws.readyState === 1) {
      ws.send(JSON.stringify({ type: 'data', data }));
    }
  };

  if (ws.readyState === 1) {
    ws.send(JSON.stringify({ type: 'ready', runtime: DEFAULT_RUNTIME }));
  }
  term.onData(onData);

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(String(raw));
      if (msg.type === 'input' && typeof msg.data === 'string') {
        term.write(msg.data);
        return;
      }
      if (msg.type === 'resize' && Number.isInteger(msg.cols) && Number.isInteger(msg.rows)) {
        term.resize(Math.max(20, msg.cols), Math.max(10, msg.rows));
      }
    } catch {
      // ignore malformed client frames in v0
    }
  });

  const cleanup = () => {
    try {
      term.kill();
    } catch {
      // ignore cleanup errors in v0
    }
  };

  ws.on('close', cleanup);
  ws.on('error', cleanup);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`TRUERUL web terminal listening on http://0.0.0.0:${PORT} :: runtime=${DEFAULT_RUNTIME}`);
});
