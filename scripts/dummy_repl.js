import readline from 'readline';
import { parseQuoted, printQuoted } from '../packages/surface/quoted.js';
import { createRuntime, evaluateForm } from '../packages/core-language/runtime.js';

const C = {
  reset: '\u001b[0m',
  cyan: '\u001b[36m',
  rust: '\u001b[38;5;173m',
  yellow: '\u001b[33m',
  red: '\u001b[31m',
  green: '\u001b[32m',
  gray: '\u001b[90m',
  bold: '\u001b[1m'
};

const runtime = createRuntime();

const print = (text = '') => process.stdout.write(text);
const line = (text = '') => process.stdout.write(text + '\r\n');

function banner() {
  line(`${C.cyan}${C.bold}TRUERUL${C.reset} ${C.gray}:: ${runtime.lang} :: cycle ${String(runtime.cycle).padStart(2, '0')}${C.reset}`);
  line(`${C.gray}quoted forms / terminal body v0${C.reset}`);
  line('');
}

function prompt() {
  print(`${C.rust}>${C.reset} `);
}

function showHelp() {
  line(`${C.yellow}[help]${C.reset}`);
  line('(entity <id> :kind <kind>)');
  line('(relation <subject> <predicate> <object>)');
  line('(state <target> <state>)');
  line('(rule <id>? :if <condition> :then <consequence>)');
  line('(query <pattern>)');
  line('(quote <form>)');
  line('(eval <form>)');
  line('(view <name>?)');
  line('(log)');
  line('(step)');
  line('(surface :lang ru|en)');
  line('(help)');
}

function showLog(entries) {
  line(`${C.yellow}[log]${C.reset}`);
  if (!entries.length) {
    line(`${C.gray}no log entries yet; the forms are still composing themselves${C.reset}`);
    return;
  }
  entries.forEach((entry, index) => {
    switch (entry.type) {
      case 'entity':
        line(`${String(index + 1).padStart(2, '0')}. entity ${entry.id} :kind ${entry.kind}`);
        break;
      case 'relation':
        line(`${String(index + 1).padStart(2, '0')}. relation ${entry.subject} ${entry.predicate} ${entry.object}`);
        break;
      case 'state':
        line(`${String(index + 1).padStart(2, '0')}. state ${entry.target} ${entry.state}`);
        break;
      case 'query':
        line(`${String(index + 1).padStart(2, '0')}. query ${entry.pattern}`);
        break;
      case 'step':
        line(`${String(index + 1).padStart(2, '0')}. step -> cycle ${entry.cycle}`);
        break;
      default:
        line(`${String(index + 1).padStart(2, '0')}. ${JSON.stringify(entry)}`);
    }
  });
}

function showQuery(matches) {
  line(`${C.yellow}[query]${C.reset}`);
  if (!matches.length) {
    line(`${C.gray}∅${C.reset}`);
    return;
  }
  matches.forEach((binding) => {
    const pairs = Object.entries(binding);
    if (!pairs.length) {
      line(`${C.gray}true${C.reset}`);
      return;
    }
    line(pairs.map(([k, v]) => `${k} = ${v}`).join(', '));
  });
}

function showResult(result) {
  switch (result.kind) {
    case 'ok':
      line(`${C.green}[ok]${C.reset} ${result.message}`);
      break;
    case 'error':
      line(`${C.red}[error]${C.reset} ${result.message}`);
      break;
    case 'query':
      showQuery(result.matches);
      break;
    case 'form':
      line(`${C.cyan}[form]${C.reset}`);
      line(printQuoted(result.form));
      break;
    case 'log':
      showLog(result.entries);
      break;
    case 'help':
      showHelp();
      break;
    case 'clear':
      print('\u001bc');
      banner();
      break;
    default:
      line(`${C.red}[error]${C.reset} unrecognized result kind`);
  }
}

function processInput(input) {
  const trimmed = input.trim();
  if (!trimmed) return;

  try {
    const form = parseQuoted(trimmed);
    const result = evaluateForm(runtime, form, { printQuoted });
    showResult(result);
  } catch (error) {
    line(`${C.red}[error]${C.reset} ${error.message}`);
  }
}

banner();
prompt();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: true,
  historySize: 200
});

rl.on('line', (input) => {
  processInput(input);
  prompt();
});

rl.on('SIGINT', () => {
  line('');
  line(`${C.red}[interrupt]${C.reset} the forms protest, but remain in memory`);
  prompt();
});
