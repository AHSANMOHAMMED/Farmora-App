# -*- coding: utf-8 -*-
"""Merge a translation fragment into lib/l10n/app_{en,ta,si}.arb and
regenerate AppLocalizations.

Usage (from the project root):
    python tool/l10n_merge.py path/to/fragment.json [--no-gen]

Fragment format (UTF-8 JSON):
{
  "keys": {
    "farmerAddProductTitle": {
      "en": "Add product", "ta": "...", "si": "...",
      "placeholders": {"count": {"type": "int"}},   # optional, en only
      "uncertain": true                              # optional, review flag
    }
  },
  "overrides": {                                     # optional: fix values of
    "logOut": {"ta": "...", "si": "..."}             # EXISTING keys
  }
}

Rules:
  * A new key must not already exist with a different English text
    (reuse the existing key instead, or pick a new name).
  * Every key needs en, ta and si.
  * Uncertain translations are recorded in tool/l10n_uncertain.json and
    marked in translations_review.csv.
A lock file serialises concurrent merges.
"""
import json
import os
import subprocess
import sys
import time
from collections import OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARB = os.path.join(ROOT, 'lib', 'l10n', 'app_%s.arb')
LOCK = os.path.join(ROOT, 'tool', '.l10n_merge.lock')
UNCERTAIN = os.path.join(ROOT, 'tool', 'l10n_uncertain.json')
LANGS = ['en', 'ta', 'si']


def _acquire():
    deadline = time.time() + 600
    while True:
        try:
            fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(os.getpid()).encode())
            os.close(fd)
            return
        except FileExistsError:
            # Stale lock (> 5 min) is removed.
            try:
                if time.time() - os.path.getmtime(LOCK) > 300:
                    os.remove(LOCK)
                    continue
            except OSError:
                pass
            if time.time() > deadline:
                sys.exit('Timed out waiting for %s' % LOCK)
            time.sleep(1)


def _load(lang):
    with open(ARB % lang, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def _save(lang, data):
    with open(ARB % lang, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def merge(fragment_path, gen=True):
    with open(fragment_path, encoding='utf-8') as f:
        frag = json.load(f, object_pairs_hook=OrderedDict)
    keys = frag.get('keys', {})
    overrides = frag.get('overrides', {})
    errors = []
    for k, v in keys.items():
        for lang in LANGS:
            if not isinstance(v.get(lang), str) or not v[lang].strip():
                errors.append('%s: missing %s' % (k, lang))
        if k.startswith('@') or not k[0].islower() or not k.isidentifier():
            errors.append('%s: invalid key name' % k)

    _acquire()
    try:
        arbs = {lang: _load(lang) for lang in LANGS}
        for k, v in keys.items():
            if k in arbs['en'] and arbs['en'][k] != v.get('en'):
                errors.append('%s: already exists with en=%r (yours %r)'
                              % (k, arbs['en'][k], v.get('en')))
        for k in overrides:
            if k not in arbs['en']:
                errors.append('override %s: key does not exist' % k)
        if errors:
            sys.exit('Merge refused:\n  ' + '\n  '.join(errors))

        for k, v in keys.items():
            for lang in LANGS:
                arbs[lang][k] = v[lang]
            if v.get('placeholders'):
                arbs['en']['@' + k] = {'placeholders': v['placeholders']}
        for k, v in overrides.items():
            for lang, text in v.items():
                if lang in LANGS and lang != 'en' and text.strip():
                    arbs[lang][k] = text
            if 'en' in v:
                arbs['en'][k] = v['en']
        for lang in LANGS:
            _save(lang, arbs[lang])

        flagged = {k for k, v in keys.items() if v.get('uncertain')}
        flagged |= {k for k, v in overrides.items() if v.get('uncertain')}
        if flagged:
            existing = []
            if os.path.exists(UNCERTAIN):
                with open(UNCERTAIN, encoding='utf-8') as f:
                    existing = json.load(f)
            with open(UNCERTAIN, 'w', encoding='utf-8') as f:
                json.dump(sorted(set(existing) | flagged), f,
                          ensure_ascii=False, indent=2)

        if gen:
            flutter = 'flutter.bat' if os.name == 'nt' else 'flutter'
            subprocess.run([flutter, 'gen-l10n'], cwd=ROOT, check=True)
        print('Merged %d keys, %d overrides from %s'
              % (len(keys), len(overrides), fragment_path))
    finally:
        try:
            os.remove(LOCK)
        except OSError:
            pass


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    merge(sys.argv[1], gen='--no-gen' not in sys.argv)
