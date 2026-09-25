# -*- coding: utf-8 -*-
"""Writes translations_review.csv (key, en, ta, si, needs_review) from the ARB
files so a native speaker can check the Tamil and Sinhala text.

Usage (from the project root):  python tool/l10n_review_csv.py

needs_review = "yes" for translations flagged uncertain when they were added
(tool/l10n_uncertain.json). Open the CSV in Excel/Google Sheets as UTF-8.
"""
import csv
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(lang):
    with open(os.path.join(ROOT, 'lib', 'l10n', 'app_%s.arb' % lang),
              encoding='utf-8') as f:
        return json.load(f)


def main():
    en, ta, si = load('en'), load('ta'), load('si')
    uncertain_path = os.path.join(ROOT, 'tool', 'l10n_uncertain.json')
    uncertain = set()
    if os.path.exists(uncertain_path):
        with open(uncertain_path, encoding='utf-8') as f:
            uncertain = set(json.load(f))
    out = os.path.join(ROOT, 'translations_review.csv')
    # utf-8-sig so Excel shows Tamil/Sinhala correctly.
    with open(out, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f)
        w.writerow(['key', 'en', 'ta', 'si', 'needs_review'])
        for key in sorted(k for k in en if not k.startswith('@')):
            w.writerow([key, en[key], ta.get(key, ''), si.get(key, ''),
                        'yes' if key in uncertain else ''])
    print('Wrote %s (%d flagged for review)' % (out, len(uncertain)))


if __name__ == '__main__':
    main()
