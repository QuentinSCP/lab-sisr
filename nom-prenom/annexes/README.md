# Annexes

Toutes les **preuves** citées dans les fiches descriptives et dans le tableau de l'environnement sont déposées ici.

## Organisation conseillée

```
annexes/
├── dat/            ← DAT d'environnement, table de correspondance GSB, DAT R1, DAT R2
├── schemas/        ← schémas d'architecture (as built), schémas des flux
├── procedures/     ← procédures d'installation et d'exploitation, réutilisables par un tiers
├── scripts/        ← scripts et configurations (sans secret)
├── captures/       ← captures numérotées et légendées
└── tests/          ← plan de tests, rapports de tests, rapports d'incident
```

*Crée un sous-dossier seulement quand tu as une première pièce à y déposer.*

## Conventions

- **Un fichier = une preuve** identifiable : cite son chemin dans la fiche descriptive.
- **Captures** : `AAAA-MM-JJ-sujet-numero.png` (par exemple `2026-10-29-pfsense-regles-01.png`), avec une **légende** dans le document qui les cite.
- **Schémas** : au format image **et** au format source si possible.
- **DAT** : un fichier par DAT (`dat-environnement.md`, `dat-r1.md`, `dat-r2.md`), plus la **table de correspondance** avec les zones de GSB (`correspondance-gsb.md`).
- **Aucun secret** dans aucun fichier : mots de passe, clés privées, jetons, certificats privés.

## Pièces attendues

| Pièce | Séance | Dossier |
|---|---|---|
| DAT d'environnement | S3 | `dat/` |
| Table de correspondance GSB ↔ mon réseau | S3 | `dat/` |
| DAT de la réalisation 1 | S4 | `dat/` |
| Procédures de la réalisation 1 | S5 – S6 | `procedures/` |
| Plan et rapport de tests, rapport d'incident (R1) | S7 | `tests/` |
| DAT de la réalisation 2 | S10 | `dat/` |
| Procédures, tests et rapport d'incident (R2) | S11 – S13 | `procedures/`, `tests/` |
