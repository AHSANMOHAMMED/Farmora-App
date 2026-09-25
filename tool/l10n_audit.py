import re, os, collections, sys

S = r"""(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")"""
pats = [
    ('Text', re.compile(r"\bText\(\s*(" + S + ")")),
    ('TextSpan', re.compile(r"\bTextSpan\([^)]*?text:\s*(" + S + ")")),
    ('prop', re.compile(r"\b(?:hintText|labelText|helperText|errorText|tooltip|title|label|subtitle|message|semanticLabel|confirmText|cancelText|body|description|emptyText|actionLabel|heading)\s*:\s*(" + S + ")")),
    ('return', re.compile(r"\breturn\s+(" + S + r")\s*;")),
    ('throw', re.compile(r"\bthrow\s+\w*(?:Exception|Error)\(\s*(" + S + ")")),
    ('snackmsg', re.compile(r"(?:showSnack\w*|_snack\w*|_toast|showError\w*|_showMessage|_showError)\(\s*(?:context,\s*)?(" + S + ")")),
]
letters = re.compile(r"[A-Za-z]{2,}")


def ok(s):
    body = s[1:-1]
    b2 = re.sub(r"\$\{[^}]*\}|\$\w+", "", body).strip()
    if not letters.search(b2):
        return False
    if re.fullmatch(r"[a-z_]+(\.[a-z_]+)*|[a-z]+[A-Z]\w*|[A-Z_]+|https?:.*|assets/.*|.*\.(png|jpg|svg|json)", b2):
        return False
    if b2 in ('Farmora', 'LKR', 'OK', 'km', 'kg'):
        return False
    return True


res = {}
samples = {}
for root, _, fs in os.walk('lib'):
    if 'l10n' in root:
        continue
    for f in fs:
        if not f.endswith('.dart') or f in ('farmora_strings.dart', 'firebase_options.dart'):
            continue
        p = os.path.join(root, f).replace(os.sep, '/')
        src = open(p, encoding='utf-8').read()
        c = collections.Counter()
        ex = []
        for name, rx in pats:
            for m in rx.finditer(src):
                if ok(m.group(1)):
                    c[name] += 1
                    ex.append(m.group(1)[:60])
        if sum(c.values()):
            res[p] = c
            samples[p] = ex

tot = collections.Counter()
for p, c in sorted(res.items(), key=lambda kv: -sum(kv[1].values())):
    tot.update(c)
    print("%4d  %s  %s" % (sum(c.values()), p, dict(c)))
print("TOTAL", sum(tot.values()), dict(tot), "files", len(res))
for p in sys.argv[1:]:
    print(p, samples.get(p, [])[:40])
