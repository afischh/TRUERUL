export function tokenize(input) {
  const tokens = [];
  let i = 0;

  while (i < input.length) {
    const ch = input[i];

    if (/\s/.test(ch)) {
      i += 1;
      continue;
    }

    if (ch === '(' || ch === ')') {
      tokens.push({ type: ch, value: ch });
      i += 1;
      continue;
    }

    if (ch === '"') {
      let j = i + 1;
      let value = '';
      while (j < input.length) {
        const cj = input[j];
        if (cj === '\\' && j + 1 < input.length) {
          value += input[j + 1];
          j += 2;
          continue;
        }
        if (cj === '"') break;
        value += cj;
        j += 1;
      }
      if (j >= input.length || input[j] !== '"') {
        throw new Error('unterminated string literal');
      }
      tokens.push({ type: 'string', value });
      i = j + 1;
      continue;
    }

    let j = i;
    let value = '';
    while (j < input.length && !/\s/.test(input[j]) && input[j] !== '(' && input[j] !== ')') {
      value += input[j];
      j += 1;
    }
    tokens.push({ type: 'symbol', value });
    i = j;
  }

  return tokens;
}

function parseExpr(tokens, index = 0) {
  const token = tokens[index];
  if (!token) throw new Error('unexpected end of input');

  if (token.type === '(') {
    const list = [];
    let cursor = index + 1;
    while (cursor < tokens.length && tokens[cursor].type !== ')') {
      const parsed = parseExpr(tokens, cursor);
      list.push(parsed.node);
      cursor = parsed.next;
    }
    if (!tokens[cursor] || tokens[cursor].type !== ')') {
      throw new Error('missing closing parenthesis');
    }
    return { node: list, next: cursor + 1 };
  }

  if (token.type === 'string') {
    return { node: { type: 'string', value: token.value }, next: index + 1 };
  }

  if (token.type === 'symbol') {
    return { node: token.value, next: index + 1 };
  }

  throw new Error(`unexpected token: ${token.value}`);
}

export function parseQuoted(input) {
  const tokens = tokenize(input);
  const parsed = parseExpr(tokens, 0);
  if (parsed.next !== tokens.length) {
    throw new Error('extra tokens after form');
  }
  return parsed.node;
}

export function printQuoted(node) {
  if (Array.isArray(node)) {
    return `(${node.map(printQuoted).join(' ')})`;
  }
  if (node && typeof node === 'object' && node.type === 'string') {
    return JSON.stringify(node.value);
  }
  return String(node);
}
