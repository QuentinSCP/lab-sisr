# Annexes

Toutes les **preuves** citées dans les fiches descriptives et dans le tableau de l'environnement sont déposées ici. Elles décrivent le laboratoire de Quentin Scarpa : un site qui reste en ligne quand un serveur tombe (réalisation 1), puis l'exploitation et la sécurité du laboratoire (réalisation 2, projet Sentinelle).

## Organisation conseillée

```text
annexes/
├── dat/          DAT du laboratoire, DAT d'environnement, table de correspondance GSB, DAT R1
├── schemas/      Schémas d'architecture, en image et en source quand elle existe (.mmd)
├── procedures/   Procédures 00 à 08 et leur version PDF (procedures/pdf/)
├── scripts/      Scripts et configurations sans secret : collecte des preuves, mesure des bascules, génération des PDF et sa charte (pdf/) ;
│                 fichiers relevés sur les machines, rangés par technologie
├── captures/     Traces relevées sur le labo, un sous-dossier par technologie (créé par les scripts)
└── tests/        Plan de tests R1 ; rapports de tests et d'incident à venir
```

## Conventions

- **Un fichier = une preuve** identifiable : son chemin est cité dans la fiche descriptive.
- **Captures** : `AAAA-MM-JJ-sujet-numero.png` (par exemple `2026-10-29-pfsense-regles-01.png`), avec une **légende** dans le document qui les cite.
- **Schémas** : au format image **et** au format source quand il existe.
- **DAT** : un fichier par DAT (`dat-environnement.md`, `dat-r1.md`, `dat-r2.md`), plus la table de correspondance (`correspondance-gsb.md`).
- **Aucun secret** : ni mot de passe, ni clé privée, ni `wp-config.php` réel. Les procédures utilisent des valeurs entre chevrons (`<MOT_DE_PASSE>`) à remplacer à la main.
- **« à vérifier »** : valeur reprise d'un échange, pas encore relevée sur la machine ; liste complète au [§18 du DAT](dat/dat-laboratoire.md#18-points-à-vérifier).
- **Fins de ligne** : le fichier `.gitattributes` du dépôt garde les scripts shell en LF, même dans un clone Windows ; sans cela, ils échouent sous WSL ou Git Bash.

## Pièces attendues

| Pièce | Séance | Fichier | État |
| --- | --- | --- | --- |
| DAT d'environnement | S3 | [`dat/dat-environnement.md`](dat/dat-environnement.md) | 🟠 |
| Table de correspondance GSB ↔ mon réseau | S3 | [`dat/correspondance-gsb.md`](dat/correspondance-gsb.md) | 🟠 |
| DAT de la réalisation 1 | S4 | [`dat/dat-r1.md`](dat/dat-r1.md) | 🟠 version 0.1 |
| Procédures de la réalisation 1 | S5 – S6 | [`procedures/`](procedures/) | 🟠 01 à 08, valeurs à relever sur les machines |
| Plan et rapport de tests, rapport d'incident (R1) | S7 | [`tests/`](tests/) | 🟠 plan prêt, rapports à venir |
| DAT de la réalisation 2 | S10 | `dat/dat-r2.md` | ⬜ |
| Procédures, tests et rapport d'incident (R2) | S11 – S13 | `procedures/`, `tests/` | ⬜ |

*Légende : ⬜ non démarré · 🟠 en cours · ✅ validé par le formateur.*

Le [DAT complet du laboratoire](dat/dat-laboratoire.md) (cible Sentinelle, choix, journaux, modèle OSI) complète ces pièces.

## Le laboratoire en bref

![Vue d'ensemble du laboratoire](schemas/01-vue-ensemble.png)

Tout passe par **pfSense** : il publie le site sur son interface WAN (`10.2.0.198:8081`) et n'autorise entre les zones que les flux de la matrice ([DAT §7](dat/dat-laboratoire.md#7-réseau--zones-adressage-et-flux)).

| VLAN | Zone | Réseau | Contenu |
| --- | --- | --- | --- |
| 164 | WEB | 10.100.164.0/24 | HAProxy, WEB1, WEB2 |
| 165 | ADM | 10.100.165.0/24 | ADPSQS (Active Directory, DNS, DHCP) |
| 166 | BDD | 10.100.166.0/24 | DB1, DB2, DB3 (grappe Galera) |
| 167 | USERS | 10.100.167.0/24 | Postes clients (à venir) |

Chaîne web : **navigateur → pfSense (NAT) → HAProxy → WEB1 ou WEB2 → HAProxy → Galera (DB1, secours DB2 et DB3)**.

## Procédures

Une procédure par technologie en place, sur le plan du [modèle 00](procedures/00-modele.md) : valeurs du labo, installation pas à pas, vérifications, dépannage, preuves à conserver.

| N° | Technologie | Rôle dans le labo | Machine(s) | État | Procédure | PDF |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | Proxmox VE | VM, réseau virtuel (VLAN), sauvegardes vzdump | Cluster de l'école | Partiel (sauvegardes à planifier) | [01](procedures/01-proxmox-vm-reseau.md) | [PDF](procedures/pdf/01-proxmox-vm-reseau.pdf) |
| 02 | pfSense | Routage, filtrage, NAT, publication du site | pfSense (611) | Partiel | [02](procedures/02-pfsense.md) | [PDF](procedures/pdf/02-pfsense.pdf) |
| 03 | OpenSSH et clés | Administration à distance sans mot de passe | Toutes les VM | En place | [03](procedures/03-ssh-par-cle.md) | [PDF](procedures/pdf/03-ssh-par-cle.pdf) |
| 04 | Active Directory, DNS, DHCP | Domaine `qscarpa.lan`, noms, adresses | ADPSQS (606) | Partiel (DHCP à venir) | [04](procedures/04-active-directory-dns-dhcp.md) | [PDF](procedures/pdf/04-active-directory-dns-dhcp.pdf) |
| 05 | Apache, PHP, WordPress | Le site public | WEB1 (609), WEB2 (615) | En place | [05](procedures/05-apache-php-wordpress.md) | [PDF](procedures/pdf/05-apache-php-wordpress.pdf) |
| 06 | MariaDB et Galera | Base du site, réplication synchrone, contrôle de santé | DB1 (612), DB2 (613), DB3 (614) | En place | [06](procedures/06-mariadb-galera.md) | [PDF](procedures/pdf/06-mariadb-galera.pdf) |
| 07 | HAProxy | Répartition web, bascule SQL | HAProxy (616) | En place | [07](procedures/07-haproxy.md) | [PDF](procedures/pdf/07-haproxy.pdf) |
| 08 | Bascules et retour à la normale | Pannes, maintenance sans coupure, mesure des délais (R1) | HAProxy, WEB1, WEB2, DB1 à DB3 | Délais à mesurer | [08](procedures/08-bascules-et-retour-a-la-normale.md) | [PDF](procedures/pdf/08-bascules-et-retour-a-la-normale.pdf) |

Les procédures sont rédigées à partir du DAT v1.4 : les valeurs marquées « à vérifier » restent à relever sur les machines avant d'être citées comme preuves.

## Relever les preuves

Les procédures décrivent ce qui est attendu ; les preuves viennent des machines. Deux scripts, lancés depuis la racine du rendu sur le poste d'administration, les relèvent sans rien modifier sur le labo.

```bash
annexes/scripts/collecte-preuves.sh
```

Il relève l'état de HAProxy, WEB1, WEB2 et DB1 à DB3 (versions, services, indicateurs, journaux) dans `annexes/captures/<technologie>/`, et leurs configurations réelles dans `annexes/scripts/<technologie>/`, mots de passe masqués.

```bash
annexes/scripts/mesure-bascule.sh http://10.2.0.198:8081/ 60 panne-web1
```

Il interroge le site toutes les 0,5 s pendant qu'une panne est provoquée dans un autre terminal, puis donne la plus longue interruption ([procédure 08](procedures/08-bascules-et-retour-a-la-normale.md#47-mesurer-une-interruption)). Relire `git diff` avant chaque commit : les sorties contiennent les adresses du labo.

## Générer les procédures en PDF

```bash
python annexes/scripts/generer-pdf.py
```

Chaque procédure `procedures/NN-*.md` (sauf le modèle 00) devient `procedures/pdf/NN-*.pdf`, dans la charte de ma documentation GLPI : page de garde, sommaire, sections numérotées et colorées, encadrés, blocs de commandes titrés, figures légendées, numéros de page. Pour une seule procédure : `python annexes/scripts/generer-pdf.py annexes/procedures/07-haproxy.md`.

- **Prérequis** : Python 3 et pypdf (`pip install pypdf`), [pandoc](https://pandoc.org/installing.html) 3 (sous Windows : `winget install JohnMacFarlane.Pandoc`), et Edge, Chrome ou Chromium en version 131 ou plus (pour le pied de page). Le navigateur est trouvé tout seul ; sinon, donner son chemin dans la variable `NAVIGATEUR`.
- **Page de garde** : elle lit l'en-tête YAML de la procédure (sous-titre, version, date, statut, diffusion, machines, outils et composants, historique). Les champs et la liste des icônes sont dans le [modèle 00](procedures/00-modele.md). À chaque nouvelle version : changer `version` et `date`, ajouter une ligne à `historique`.
- **Charte** : dossier [`scripts/pdf/`](scripts/pdf/) : `modele.html` (page de garde), `style.css` (mise en page), `filtre.lua` (sections, encadrés, blocs de code), `fond.html` (décor des pages), `polices/` (Questrial et DejaVu Sans Mono, licences libres jointes).
- **Encadrés** : une citation (`> ...`) devient un encadré « Remarque » ; si elle commence par « Attention » ou « Important », un encadré orange.
- **Schémas** : les diagrammes sont insérés en image (SVG ou PNG), seuls dans leur paragraphe : ils deviennent des figures numérotées, légendées par leur texte alternatif. Un schéma Mermaid se dessine d'abord en SVG ; sa source `.mmd` reste dans `schemas/`.
- **Régénérer après chaque modification** d'une procédure, puis committer le Markdown et le PDF ensemble.

## Rejouer le laboratoire

Ordre conseillé pour reconstruire la chaîne web de zéro. Chaque étape dépend de la précédente.

1. **01 Proxmox** : créer les VM et les placer dans leur VLAN.
2. **02 pfSense** : interfaces, règles, NAT. Sans lui, les zones ne se voient pas.
3. **03 SSH** : accès par clé à toutes les VM.
4. **04 Active Directory et DNS** : noms des serveurs (le DNS doit répondre avant le reste).
5. **06 Galera** : la base doit exister avant le site.
6. **07 HAProxy** : le site vise HAProxy pour la base (`DB_HOST`).
7. **05 Site web** : dernière brique, elle consomme toutes les autres.

## Démarrer et arrêter le laboratoire

Les VM sont éteintes entre les séances : chaque reprise est un démarrage à froid ([DAT §15](dat/dat-laboratoire.md#15-exploitation-et-administration)).

**Démarrage**

1. pfSense
2. ADPSQS (DNS et DHCP)
3. SIEM puis MON, quand ils existeront
4. Galera : amorcer **un seul** nœud, puis démarrer les deux autres un par un ([procédure 06](procedures/06-mariadb-galera.md#5-démarrage-à-froid-et-reprise-après-panne))
5. HAProxy
6. WEB1 et WEB2
7. COLLAB et OPS, quand ils existeront
8. Vérifier : `wsrep_cluster_size` vaut 3, la page de statistiques HAProxy est au vert, le site répond sur `http://10.2.0.198:8081`

**Arrêt** : ordre inverse. Arrêter les nœuds Galera un par un et **noter le dernier arrêté** : c'est lui qu'on amorcera au prochain démarrage.
