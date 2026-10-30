#!/usr/bin/env python3
"""Génère la version PDF des procédures : annexes/procedures/NN-*.md -> annexes/procedures/pdf/NN-*.pdf

Usage (depuis la racine du rendu) :
    python annexes/scripts/generer-pdf.py                  toutes les procédures, sauf le modèle 00
    python annexes/scripts/generer-pdf.py FICHIER.md ...   seulement ces fichiers

Prérequis : pandoc 3 et un navigateur Chromium (Edge, Chrome ou Chromium).
Si le navigateur n'est pas trouvé, donner son chemin dans la variable NAVIGATEUR.
La mise en page est dans pdf.css, à côté de ce script.
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

RENDU = pathlib.Path(__file__).resolve().parents[2]
PROCEDURES = RENDU / "annexes" / "procedures"
CSS = pathlib.Path(__file__).with_name("pdf.css")
# Un PDF ne peut pas pointer vers un fichier du dépôt : les liens locaux deviennent du texte.
FILTRE = """function Link(el)
  if el.target:match("^https?:") or el.target:match("^#") then return el end
  return el.content
end
"""


def navigateur():
    candidats = [
        os.environ.get("NAVIGATEUR"),
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        *(shutil.which(n) for n in ("chromium", "chromium-browser", "google-chrome", "microsoft-edge")),
    ]
    for c in candidats:
        if c and pathlib.Path(c).exists():
            return c
    sys.exit("Navigateur introuvable : donner le chemin d'Edge, de Chrome ou de Chromium dans NAVIGATEUR.")


def titre(md):
    for ligne in md.read_text(encoding="utf-8").splitlines():
        if ligne.startswith("# "):
            return ligne[2:].strip()
    return md.stem


def main():
    if not shutil.which("pandoc"):
        sys.exit("pandoc introuvable : https://pandoc.org/installing.html")
    fichiers = [pathlib.Path(a).resolve() for a in sys.argv[1:]] or sorted(
        p for p in PROCEDURES.glob("*.md") if not p.name.startswith("00-"))
    nav = navigateur()
    sortie = PROCEDURES / "pdf"
    sortie.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        filtre = pathlib.Path(tmp) / "liens.lua"
        filtre.write_text(FILTRE, encoding="utf-8")
        for md in fichiers:
            html = pathlib.Path(tmp) / (md.stem + ".html")
            pdf = sortie / (md.stem + ".pdf")
            subprocess.run(["pandoc", str(md), "-f", "gfm", "-t", "html5", "--standalone", "--embed-resources",
                            "--css", str(CSS), "--resource-path", str(md.parent), "--lua-filter", str(filtre),
                            "--metadata", f"pagetitle={titre(md)}", "-o", str(html)], check=True)
            pdf.unlink(missing_ok=True)
            options = ["--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header",
                       f"--print-to-pdf={pdf}"]
            if hasattr(os, "geteuid") and os.geteuid() == 0:
                options.append("--no-sandbox")  # Chromium refuse de tourner en root sans cette option
            subprocess.run([nav, *options, html.as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if not pdf.exists():
                sys.exit(f"Échec de l'impression de {md.name}")
            print("PDF :", pdf.relative_to(RENDU).as_posix())


main()
