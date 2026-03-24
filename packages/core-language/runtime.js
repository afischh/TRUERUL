export function createRuntime() {
  return {
    cycle: 0,
    lang: 'RU',
    forms: [],
    entities: new Map(),
    relations: [],
    states: [],
    log: []
  };
}

function atomValue(node) {
  if (node && typeof node === 'object' && node.type === 'string') return node.value;
  return node;
}

function listToAttrs(items, startIndex = 0) {
  const attrs = {};
  for (let i = startIndex; i < items.length; i += 2) {
    const key = atomValue(items[i]);
    const valueNode = items[i + 1];
    if (typeof key === 'string' && key.startsWith(':') && valueNode !== undefined) {
      attrs[key.slice(1)] = atomValue(valueNode);
    }
  }
  return attrs;
}

function logPush(rt, entry) {
  rt.log.push(entry);
}

export function evaluateForm(rt, form, helpers = {}) {
  const { printQuoted = (x) => String(x) } = helpers;

  if (!Array.isArray(form) || form.length === 0) {
    return { kind: 'error', message: 'form must be a non-empty list' };
  }

  const head = atomValue(form[0]);

  switch (head) {
    case 'entity': {
      const id = atomValue(form[1]);
      const attrs = listToAttrs(form, 2);
      const kind = attrs.kind ?? attrs.тип ?? 'thing';
      rt.entities.set(id, { id, kind, attrs });
      rt.forms.push(form);
      logPush(rt, { type: 'entity', id, kind });
      return { kind: 'ok', message: `entity registered: ${id} :: kind ${kind}` };
    }

    case 'relation': {
      const subject = atomValue(form[1]);
      const predicate = atomValue(form[2]);
      const object = atomValue(form[3]);
      const rel = { subject, predicate, object };
      rt.relations.push(rel);
      rt.forms.push(form);
      logPush(rt, { type: 'relation', subject, predicate, object });
      return { kind: 'ok', message: `relation registered: ${subject} --${predicate}--> ${object}` };
    }

    case 'state': {
      const target = atomValue(form[1]);
      const state = atomValue(form[2]);
      const st = { target, state };
      rt.states.push(st);
      rt.forms.push(form);
      logPush(rt, { type: 'state', target, state });
      return { kind: 'ok', message: `state registered: ${target} :: ${state}` };
    }

    case 'query': {
      const pattern = form[1];
      if (!Array.isArray(pattern) || pattern.length === 0) {
        return { kind: 'error', message: 'query expects a pattern list' };
      }
      const phead = atomValue(pattern[0]);

      if (phead === 'relation?') {
        const subject = atomValue(pattern[1]);
        const predicate = atomValue(pattern[2]);
        const object = atomValue(pattern[3]);
        const matches = rt.relations.filter((r) => {
          const sOk = subject === 'X' || subject === '_' || r.subject === subject;
          const pOk = predicate === 'X' || predicate === '_' || r.predicate === predicate;
          const oOk = object === 'X' || object === '_' || r.object === object;
          return sOk && pOk && oOk;
        }).map((r) => {
          const binding = {};
          if (subject === 'X') binding.X = r.subject;
          if (predicate === 'X') binding.X = r.predicate;
          if (object === 'X') binding.X = r.object;
          if (subject === 'Y') binding.Y = r.subject;
          if (predicate === 'Y') binding.Y = r.predicate;
          if (object === 'Y') binding.Y = r.object;
          return binding;
        });

        logPush(rt, { type: 'query', pattern: printQuoted(pattern) });
        return { kind: 'query', label: 'query', matches };
      }

      if (phead === 'entity?') {
        const id = atomValue(pattern[1]);
        const attrs = listToAttrs(pattern, 2);
        const kind = attrs.kind ?? attrs.тип;
        const matches = [];
        for (const entity of rt.entities.values()) {
          const idOk = id === 'X' || id === '_' || entity.id === id;
          const kindOk = kind === undefined || kind === 'X' || kind === '_' || entity.kind === kind;
          if (idOk && kindOk) {
            const binding = {};
            if (id === 'X') binding.X = entity.id;
            if (kind === 'X') binding.X = entity.kind;
            if (id === 'Y') binding.Y = entity.id;
            if (kind === 'Y') binding.Y = entity.kind;
            matches.push(binding);
          }
        }
        logPush(rt, { type: 'query', pattern: printQuoted(pattern) });
        return { kind: 'query', label: 'query', matches };
      }

      if (phead === 'state?') {
        const target = atomValue(pattern[1]);
        const state = atomValue(pattern[2]);
        const matches = rt.states.filter((s) => {
          const tOk = target === 'X' || target === '_' || s.target === target;
          const stOk = state === 'X' || state === '_' || s.state === state;
          return tOk && stOk;
        }).map((s) => {
          const binding = {};
          if (target === 'X') binding.X = s.target;
          if (state === 'X') binding.X = s.state;
          if (target === 'Y') binding.Y = s.target;
          if (state === 'Y') binding.Y = s.state;
          return binding;
        });
        logPush(rt, { type: 'query', pattern: printQuoted(pattern) });
        return { kind: 'query', label: 'query', matches };
      }

      return { kind: 'error', message: `unsupported query head: ${phead}` };
    }

    case 'quote': {
      const quoted = form[1];
      return { kind: 'form', form: quoted };
    }

    case 'eval': {
      const inner = form[1];
      if (!Array.isArray(inner)) {
        return { kind: 'error', message: 'eval expects a quoted list form' };
      }
      return evaluateForm(rt, inner, helpers);
    }

    case 'log': {
      return { kind: 'log', entries: [...rt.log] };
    }

    case 'step': {
      rt.cycle += 1;
      logPush(rt, { type: 'step', cycle: rt.cycle });
      return { kind: 'ok', message: `cycle advanced to ${rt.cycle}` };
    }

    case 'surface': {
      const attrs = listToAttrs(form, 1);
      const lang = String(attrs.lang || attrs.язык || '').toUpperCase();
      if (lang !== 'RU' && lang !== 'EN') {
        return { kind: 'error', message: 'surface expects :lang ru|en' };
      }
      rt.lang = lang;
      return { kind: 'ok', message: `surface switched: ${lang}` };
    }

    case 'help': {
      return { kind: 'help' };
    }

    case 'clear': {
      return { kind: 'clear' };
    }

    default:
      return { kind: 'error', message: `unknown form head: ${head}` };
  }
}
