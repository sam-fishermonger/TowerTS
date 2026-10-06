#!/usr/bin/env python3
"""Liste les textes du jeu qui n'ont pas encore de traduction anglaise.

Cherche les textes marqués à traduire :
  - dans les scripts (.gd) : tr("…"), tr_n("…", "…", n) et atr("…") ;
  - dans les scènes (.tscn) : text, tooltip_text, placeholder_text, title, dialog_text,
    ok_button_text et cancel_button_text ;
puis affiche ceux qui manquent dans translations/en.po.

    python3 tools/textes_a_traduire.py            # liste, code de sortie 1 s'il en manque
    python3 tools/textes_a_traduire.py --ajouter  # ajoute les manquants à en.po, msgstr vide

Un msgstr vide fait échouer les tests (_test_language) : il reste à l'écrire.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PO_FILE = ROOT / "translations" / "en.po"

STRING = r'"((?:[^"\\]|\\.)*)"'
GD_CALL = re.compile(r'\b(?:tr|atr|tr_n|atr_n)\(\s*' + STRING + r'(?:\s*,\s*' + STRING + r')?')
TSCN_PROPS = ("text", "tooltip_text", "placeholder_text", "title", "dialog_text", "ok_button_text",
              "cancel_button_text")
TSCN_PROP = re.compile(r'^(?:' + "|".join(TSCN_PROPS) + r') = ' + STRING, re.MULTILINE | re.DOTALL)
# Textes qui ne se traduisent pas : vides, nombres, symboles.
NOTHING_TO_TRANSLATE = re.compile(r'^[\W\d_x%]*$')


def unescape(text: str) -> str:
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text)


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def read_po(path: Path) -> set[str]:
    """msgid du fichier .po (les msgid sur plusieurs lignes sont recollés)."""
    ids: set[str] = set()
    current: list[str] | None = None
    for line in path.read_text(encoding="utf-8").splitlines() + [""]:
        line = line.strip()
        if line.startswith("msgid "):
            current = [line[6:]]
        elif line.startswith('"') and current is not None:
            current.append(line)
        else:
            if current is not None:
                ids.add("".join(unescape(part.strip()[1:-1]) for part in current))
            current = None
    ids.discard("")
    return ids


def find_texts() -> dict[str, str]:
    """Texte -> premier fichier où il apparaît."""
    texts: dict[str, str] = {}

    def add(text: str, where: Path) -> None:
        text = unescape(text)
        if not NOTHING_TO_TRANSLATE.match(text):
            texts.setdefault(text, str(where.relative_to(ROOT)))

    for path in sorted(ROOT.glob("**/*.gd")):
        if ".godot" in path.parts:
            continue
        for match in GD_CALL.finditer(path.read_text(encoding="utf-8")):
            add(match.group(1), path)
            if match.group(2) is not None:
                add(match.group(2), path)
    for path in sorted(ROOT.glob("**/*.tscn")):
        if ".godot" in path.parts:
            continue
        for match in TSCN_PROP.finditer(path.read_text(encoding="utf-8")):
            add(match.group(1), path)
    return texts


def main() -> int:
    known = read_po(PO_FILE)
    missing = {text: where for text, where in find_texts().items() if text not in known}
    if not missing:
        print("Tous les textes marqués ont leur traduction dans translations/en.po.")
        return 0
    for text, where in missing.items():
        print(f"{where}: {text!r}")
    print(f"{len(missing)} texte(s) sans traduction.")
    if "--ajouter" in sys.argv:
        with PO_FILE.open("a", encoding="utf-8") as po:
            for text, where in missing.items():
                po.write(f'\n#: {where}\nmsgid "{escape(text)}"\nmsgstr ""\n')
        print("Ajoutés à translations/en.po : il reste à écrire leurs msgstr.")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
