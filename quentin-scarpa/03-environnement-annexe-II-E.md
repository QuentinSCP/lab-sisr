# Environnement technologique — annexe II.E

> **Outil de la commission : annexe VII-7** (« Outil d'aide à l'appréciation de l'environnement technologique »). Un environnement non conforme peut coûter **jusqu'à 15 points**.
> **Audit dès la séance 3**, mise à jour en séance 10, **finalisation en séance 14**.
> **Ne renseigner que ce qui est démontrable** : une ligne déclarée mais impossible à montrer est plus risquée qu'une ligne vide.
> Les lignes 1 à 22 sont obligatoires. Pour les lignes 23 à 26, **au moins une** solution suffit.
> *État : ✅ présent et démontrable · 🟠 présent mais pas encore démontrable · 🔴 absent.*
> *« Fourni par » : **école** ou **moi**.*

**Audit du 29 octobre 2026 (S3)**, à partir du [DAT d'environnement](docs/dat-environnement.md). « À produire » signale une preuve à capturer : `scripts/collecte-preuves.sh` relève les traces texte, les captures d'écran restent à faire à la main.

## 1.1 — Environnement commun

| # | Élément exigé | Outil retenu | Fourni par | Preuve (annexe) | État |
|---|---|---|---|---|---|
| 1 | Service d'authentification | Active Directory sur Windows Server 2022 (ADPSQS, VM 606), domaine `qscarpa.lan`. Annuaire encore peu exploité : pas d'OU, de groupes ni de GPO | moi | [Procédure 04](docs/procedures/04-active-directory-dns-dhcp.md) ; à produire : `Get-ADDomain`, OU et comptes | 🟠 |
| 2 | SGBD | MariaDB 10.11 en grappe Galera de 3 nœuds (DB1, DB2, DB3) | moi | [Procédure 06](docs/procedures/06-mariadb-galera.md) ; à produire : `captures/galera/…-etat.txt` | ✅ |
| 3 | Accès sécurisé à Internet | pfSense : NAT sortant et filtrage par zone ; accès Internet de l'école en amont | moi (pfSense), école (accès Internet) | [Procédure 02](docs/procedures/02-pfsense.md) ; règles et refus par défaut encore à vérifier | 🟠 |
| 4 | Environnement de travail collaboratif | Git : dépôt GitHub du labo (documents, procédures, configurations versionnés). Nextcloud prévu (COLLAB). Recevabilité de Git seul à faire confirmer par le formateur | moi | Historique des commits du dépôt | ✅ |
| 5 | Deux serveurs sur des OS différents, dont un open source | Windows Server 2022 (ADPSQS) et Debian (HAProxy, WEB1, WEB2, DB1 à DB3) | moi | [DAT d'environnement §3](docs/dat-environnement.md) ; à produire : `winver`, `cat /etc/debian_version` | ✅ |
| 6 | Solution de sauvegarde | Sauvegarde intégrée de Proxmox (vzdump) ; export logique MariaDB sur DB3 prévu. Pas de planning ni de restauration testée | école (Proxmox), moi (tâches) | [Procédure 01 §4.3](docs/procedures/01-proxmox-vm-reseau.md) ; à produire : tâche planifiée et restauration (T13) | 🟠 |
| 7 | Ressources à accès sécurisé et habilitation | Compte WordPress limité à la base `wp2026` et à l'adresse de HAProxy ; administration par clé ; page de statistiques réservée à la zone ADM. Groupes AD à créer | moi | Procédures [03](docs/procedures/03-ssh-par-cle.md), [06 §4.6](docs/procedures/06-mariadb-galera.md), [07 §4.4](docs/procedures/07-haproxy.md) | 🟠 |
| 8 | Deux types de terminaux dont un mobile | Poste d'administration (réseau de l'école) ; smartphone sur le réseau de l'école, pas encore testé | moi | À produire : le site ouvert sur le smartphone | 🔴 |

## 1.2 — Outils de gestion de la sécurité

| # | Élément exigé | Outil retenu | Fourni par | Preuve (annexe) | État |
|---|---|---|---|---|---|
| 9 | Gestion des incidents | GLPI prévu (VM OPS) | — | — | 🔴 |
| 10 | Détection et prévention d'intrusions | Suricata (pfSense) et Wazuh prévus | — | — | 🔴 |
| 11 | Chiffrement | SSH (clés ed25519) en place ; HTTPS avec autorité interne prévu sur HAProxy (R1, S5) | moi | [Procédure 03](docs/procedures/03-ssh-par-cle.md) | 🟠 |
| 12 | Analyse de trafic | Wireshark prévu (poste USERS) ; `tcpdump` installable dès maintenant sur HAProxy | — | — | 🔴 |

## 2.1 — Spécifique SISR

| # | Élément exigé | Outil retenu | Fourni par | Preuve (annexe) | État |
|---|---|---|---|---|---|
| 13 | Réseau à plusieurs périmètres de sécurité | 4 VLAN (WEB, ADM, BDD, USERS) filtrés par pfSense, refus par défaut | moi | [Procédure 02](docs/procedures/02-pfsense.md), [DAT §7](docs/DAT.md) ; à produire : règles et refus journalisé (R1-T12) | 🟠 |
| 14 | Service rendu avec contrat de service | Site web haute disponibilité ; contrat proposé avec objectifs de reprise ; mesures à faire | moi | [DAT R1 §3](docs/dat-r1.md), [plan de tests R1](docs/tests/plan-de-tests-r1.md) | 🟠 |
| 15 | Analyse de trames | Wireshark ou `tcpdump` prévus | — | — | 🔴 |
| 16 | Gestion des configurations | Git ; configurations réelles relevées par `scripts/collecte-preuves.sh` ; Ansible prévu | moi | `configs/` après la première collecte | 🟠 |
| 17 | Administration à distance sécurisée | SSH par clé, mot de passe refusé, une redirection pfSense par machine ; bastion Guacamole prévu | moi | [Procédure 03](docs/procedures/03-ssh-par-cle.md) ; à produire : connexion, refus, journal (R1-T11) | ✅ |
| 18 | Supervision avec remontée d'alertes | Prometheus, Grafana et Alertmanager prévus (VM MON). Aujourd'hui : page d'état HAProxy, sans alerte | — | — | 🔴 |
| 19 | Accès sécurisés à un service | HAProxy en mandataire inverse devant le site ; HTTPS prévu (R1, S5) | moi | [Procédure 07](docs/procedures/07-haproxy.md) | 🟠 |
| 20 | Continuité d'un service | Grappe Galera, bascule SQL par HAProxy | moi | Procédures [06](docs/procedures/06-mariadb-galera.md), [07](docs/procedures/07-haproxy.md), [08](docs/procedures/08-bascules-et-retour-a-la-normale.md) ; à produire : R1-T06 | ✅ |
| 21 | Tolérance de panne | Deux Apache et trois nœuds Galera : la panne d'un serveur web ou d'un nœud est tolérée ; keepalived prévu (R1) | moi | [Procédure 08](docs/procedures/08-bascules-et-retour-a-la-normale.md) ; à produire : R1-T03 et R1-T06 | ✅ |
| 22 | Répartition de charge | HAProxy, tour de rôle entre WEB1 et WEB2 | moi | [Procédure 07](docs/procedures/07-haproxy.md) ; à produire : R1-T02 | ✅ |

## 2.2 — Au moins une solution d'infrastructure opérationnelle

| # | Solution | Retenue (oui/non) | Outil | Preuve (annexe) | État |
|---|---|---|---|---|---|
| 23 | Connexion sécurisée entre deux sites | non | — | — | 🔴 |
| 24 | Déploiement de solutions techniques d'accès | non | GPO prévues | — | 🔴 |
| 25 | Solution gérée par procédures automatisées (scripts) | oui | Installation de l'annuaire en PowerShell (script à verser) ; contrôle de santé Galera (script et unités systemd) ; scripts de collecte et de mesure ; Ansible prévu | Procédures 04 et 06, [`scripts/`](scripts/) | 🟠 |
| 26 | Détection d'intrusions ou de comportements anormaux | oui (prévue) | Wazuh et Suricata, phase 3 | — | 🔴 |

## Bilan de l'audit

- **Lignes ✅ :** 7 / 22 (2, 4, 5, 17, 20, 21, 22)
- **Lignes 🟠 :** 9 (1, 3, 6, 7, 11, 13, 14, 16, 19)
- **Lignes 🔴 :** 6 (8, 9, 10, 12, 15, 18)
- **Solution retenue pour 23 à 26 :** 25 (scripts), en cours ; 26 (Wazuh, Suricata) prévue en phase 3
- **Trois priorités à traiter :** 1. Sauvegarde planifiée **et restauration testée** (ligne 6, test T13). 2. Supervision avec alertes (ligne 18), avant S7. 3. HTTPS avec l'autorité interne (lignes 11 et 19, exigé aussi par R1).

**Gains rapides, moins d'une heure chacun :** ouvrir le site depuis un smartphone (ligne 8) ; une capture `tcpdump` commentée du trafic SQL entre HAProxy et DB1 (lignes 12 et 15) ; capture des règles pfSense et d'un refus journalisé (ligne 13) ; première collecte de preuves (lignes 2, 16, 17, 20 à 22).
