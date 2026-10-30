#!/usr/bin/env python3
"""Génère la version PDF des procédures : annexes/procedures/NN-*.md -> annexes/procedures/pdf/NN-*.pdf

Usage (depuis la racine du rendu) :
    python annexes/scripts/generer-pdf.py                  toutes les procédures, sauf le modèle 00
    python annexes/scripts/generer-pdf.py FICHIER.md ...   seulement ces fichiers

Prérequis : Python 3 et pypdf (pip install pypdf), pandoc 3, un navigateur Chromium (Edge, Chrome ou Chromium).
Si le navigateur n'est pas trouvé, donner son chemin dans la variable NAVIGATEUR.
La charte est dans le dossier pdf/ à côté de ce script : modèle de page de garde, feuille de style,
polices, filtre pandoc et fond des pages. La page de garde lit l'en-tête YAML de chaque procédure.
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

try:
    from pypdf import PdfReader, PdfWriter
except ImportError:
    sys.exit("pypdf introuvable : pip install pypdf")

RENDU = pathlib.Path(__file__).resolve().parents[2]
PROCEDURES = RENDU / "annexes" / "procedures"
CHARTE = pathlib.Path(__file__).with_name("pdf")


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
    """Titre de la procédure sans son numéro : « 06 · MariaDB et cluster Galera » donne « MariaDB et cluster Galera »."""
    for ligne in md.read_text(encoding="utf-8").splitlines():
        if ligne.startswith("# "):
            return ligne[2:].split(" · ", 1)[-1].strip()
    return md.stem


def imprimer(nav, html, pdf):
    options = ["--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header",
               f"--print-to-pdf={pdf}"]
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        options.append("--no-sandbox")  # Chromium refuse de tourner en root sans cette option
    pdf.unlink(missing_ok=True)
    subprocess.run([nav, *options, html.as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not pdf.exists():
        sys.exit(f"Échec de l'impression de {html.name}")


def main():
    if not shutil.which("pandoc"):
        sys.exit("pandoc introuvable : https://pandoc.org/installing.html")
    fichiers = [pathlib.Path(a).resolve() for a in sys.argv[1:]] or sorted(
        p for p in PROCEDURES.glob("*.md") if not p.name.startswith("00-"))
    nav = navigateur()
    sortie = PROCEDURES / "pdf"
    sortie.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        imprimer(nav, CHARTE / "fond.html", tmp / "fond.pdf")
        fonds = PdfReader(tmp / "fond.pdf").pages
        for md in fichiers:
            html, brut, pdf = tmp / (md.stem + ".html"), tmp / (md.stem + "-brut.pdf"), sortie / (md.stem + ".pdf")
            # Titre et numéro passent par un fichier UTF-8 : en argument, les accents dépendent de la langue du système.
            meta = tmp / "meta.json"
            meta.write_text(json.dumps({"pagetitle": titre(md), "numero": md.name[:2]}), encoding="utf-8")
            subprocess.run(["pandoc", str(md), "-f", "gfm+yaml_metadata_block", "-t", "html5", "--standalone",
                            "--embed-resources", "--wrap=none", "--template", str(CHARTE / "modele.html"),
                            "--css", str(CHARTE / "style.css"), "--lua-filter", str(CHARTE / "filtre.lua"),
                            "--highlight-style", "breezedark", "--resource-path", str(md.parent),
                            "--metadata-file", str(meta), "-o", str(html)], check=True)
            imprimer(nav, html, brut)
            # Le fond décoré passe sous chaque page : fond A sur les pages impaires, fond B sur les paires.
            ecrivain = PdfWriter()
            for i, page in enumerate(PdfReader(brut).pages):
                page.merge_page(fonds[i % len(fonds)], over=False)
                ecrivain.add_page(page).compress_content_streams()  # la fusion laisse le contenu non compressé
            ecrivain.add_metadata({"/Title": titre(md), "/Author": "Quentin Scarpa"})
            with open(pdf, "wb") as f:
                ecrivain.write(f)
            print("PDF :", pdf.relative_to(RENDU).as_posix())


main()
