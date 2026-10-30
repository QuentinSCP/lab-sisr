# Séance 3 — Audit de mon laboratoire

**Étudiant :** Quentin · **Épreuve :** E6 SISR (BTS SIO) · **Date :** 29 octobre 2026

*Rendu de la séance 3 : état de mon laboratoire au 29 octobre 2026, ligne à ligne, selon la checklist de l'annexe II.E. Ce fichier est un instantané ; le tableau officiel [`03-environnement-annexe-II-E.md`](../03-environnement-annexe-II-E.md) est mis à jour en S10 et en S14.*

## 1. Ce que je rends

| N° | Rendu attendu en S3 | Où | État |
|---|---|---|---|
| 1 | Schéma de ce que j'ai réellement construit (*as built*) | [`annexes/schemas/01-vue-ensemble.png`](../annexes/schemas/01-vue-ensemble.png) | 🟠 adresses de HAProxy et de WEB2 à relever |
| 2 | Checklist d'environnement remplie, avec une preuve par ligne | §2 ci-dessous ; tableau officiel : [`03-environnement-annexe-II-E.md`](../03-environnement-annexe-II-E.md) | 🟠 captures à produire |
| 3 | Table de correspondance avec les zones de GSB | [`annexes/dat/correspondance-gsb.md`](../annexes/dat/correspondance-gsb.md) | 🟠 |
| 4 | DAT d'environnement (1 à 2 pages) | [`annexes/dat/dat-environnement.md`](../annexes/dat/dat-environnement.md) | 🟠 |
| 5 | Fiche descriptive R1 | [`01-fiche-descriptive-R1.md`](../01-fiche-descriptive-R1.md) | 🟠 version 1 |
| 6 | Journal de bord et commit | Journal : dépôt privé ; commits du 29 octobre | 🟠 journal à tenir à jour |

*Légende : ⬜ non démarré · 🟠 en cours · ✅ validé par le formateur.*

## 2. Ma checklist d'environnement

*État : ✅ présent et démontrable · 🟠 présent mais je ne sais pas encore le montrer · 🔴 absent.*

### A. Les bases (8 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|
| 1 | Un **service d'authentification** (annuaire) | Active Directory, Windows Server 2022 (ADPSQS), domaine `qscarpa.lan` ; pas encore d'OU, de groupes ni de GPO | moi | Procédure 04 ; `Get-ADDomain` à capturer | 🟠 |
| 2 | Une **base de données** | MariaDB 10.11 en grappe Galera de 3 nœuds | moi | Procédure 06 ; état relevé par la collecte | ✅ |
| 3 | Un **accès sécurisé à Internet** | pfSense : NAT sortant, filtrage par zone ; règles à vérifier | moi (pfSense), école (Internet) | Procédure 02 | 🟠 |
| 4 | Un **outil de travail collaboratif** | Git (dépôt GitHub du labo) ; Nextcloud prévu | moi | Historique des commits | ✅ |
| 5 | **Deux serveurs** sous **deux systèmes différents**, dont un open source | Windows Server 2022 et Debian | moi | DAT d'environnement §3 | ✅ |
| 6 | Une **sauvegarde** | vzdump de Proxmox ; ni planning ni restauration testée | école (Proxmox), moi | Procédure 01 §4.3 | 🟠 |
| 7 | Des **ressources à accès restreint** (habilitations) | Compte WordPress limité à sa base ; SSH par clé ; statistiques HAProxy réservées à ADM | moi | Procédures 03, 06, 07 | 🟠 |
| 8 | **Deux types de terminaux** dont **un mobile** | Poste d'administration ; smartphone pas encore testé | moi | — | 🔴 |

### B. Les outils de sécurité (4 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|
| 9 | La **gestion des incidents** | GLPI prévu | — | — | 🔴 |
| 10 | La **détection / prévention d'intrusions** | Suricata et Wazuh prévus | — | — | 🔴 |
| 11 | Le **chiffrement** | SSH par clé ; HTTPS avec autorité interne prévu (R1) | moi | Procédure 03 | 🟠 |
| 12 | L'**analyse de trafic** | Wireshark et ntopng prévus | — | — | 🔴 |

### C. Spécifique à SISR (10 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|
| 13 | Un réseau avec **plusieurs zones de sécurité** | 4 VLAN (WEB, ADM, BDD, USERS) filtrés par pfSense | moi | Procédure 02, DAT §7 ; refus journalisé à capturer | 🟠 |
| 14 | Un **service rendu à l'utilisateur** avec un **contrat de service** | Site haute disponibilité ; objectifs de reprise proposés, pas encore mesurés | moi | DAT R1 §3, plan de tests R1 | 🟠 |
| 15 | Un logiciel d'**analyse de trames** | Wireshark ou `tcpdump` prévus | — | — | 🔴 |
| 16 | Une **gestion des configurations** | Git ; configurations relevées par script ; Ansible prévu | moi | `annexes/scripts/` après la première collecte | 🟠 |
| 17 | Une **administration à distance sécurisée** | SSH par clé, mot de passe refusé ; bastion prévu | moi | Procédure 03 | ✅ |
| 18 | Une **supervision** avec **alertes** | Aucune ; page d'état HAProxy sans alerte | — | — | 🔴 |
| 19 | Des **accès sécurisés** à un service | HAProxy en mandataire inverse ; HTTPS prévu (R1) | moi | Procédure 07 | 🟠 |
| 20 | Une solution de **continuité** d'un service | Grappe Galera, bascule SQL par HAProxy | moi | Procédures 06, 07, 08 | ✅ |
| 21 | Une **tolérance de panne** | Deux Apache, trois nœuds Galera ; keepalived prévu (R1) | moi | Procédure 08 | ✅ |
| 22 | Une **répartition de charge** | HAProxy, tour de rôle entre WEB1 et WEB2 | moi | Procédure 07 | ✅ |

### D. Au moins une de ces quatre solutions

| # | Solution | Mon choix (oui/non) | Preuve | État |
|---|---|---|---|---|
| 23 | **Connexion sécurisée entre deux sites** | non | — | 🔴 |
| 24 | **Déploiement** de solutions techniques d'accès | non (GPO prévues) | — | 🔴 |
| 25 | Solution gérée par des **scripts** | oui : PowerShell (annuaire), contrôle de santé Galera, scripts de collecte et de mesure ; Ansible prévu | Procédures 04 et 06, `annexes/scripts/` | 🟠 |
| 26 | **Détection d'intrusions** ou de comportements anormaux | oui, prévue : Wazuh, Suricata | — | 🔴 |

## 3. Mon bilan à la séance 3

- **Nombre de lignes ✅ :** 7 / 22 (2, 4, 5, 17, 20, 21, 22)
- **Lignes 🟠 (à apprendre à montrer) :** 9 (1, 3, 6, 7, 11, 13, 14, 16, 19)
- **Lignes 🔴 (absentes) :** 6 (8, 9, 10, 12, 15, 18)
- **La solution (23 à 26) que je vise :** 25 (scripts), puis 26 (détection d'intrusions)

**Les 3 lignes les plus urgentes à traiter :**
1. **Ligne 6, sauvegarde** : sauvegarder chaque VM et **restaurer** l'une d'elles (test T13).
2. **Ligne 18, supervision avec alertes** : Zabbix, avant S7.
3. **Lignes 11 et 19, chiffrement** : autorité interne et HTTPS sur HAProxy, exigés aussi par R1.

**Gains rapides, moins d'une heure chacun :** ouvrir le site sur un smartphone (ligne 8) ; une capture commentée du trafic entre HAProxy et DB1 (lignes 12 et 15) ; capture des règles pfSense et d'un refus journalisé (ligne 13) ; première collecte de preuves (lignes 2, 16, 17, 20 à 22).

## 4. Les points les plus souvent oubliés

| Ligne de l'audit | Chez moi | Ce que je fais |
|---|---|---|
| **Sauvegarde** | vzdump sans planning, aucune restauration testée | Sauvegarde de chaque VM et une restauration, avant toute reconstruction (plan, phase 0) |
| **Supervision avec alertes** | Absente | Zabbix et alertes par mail (plan, phase 8) |
| **Terminal mobile** | Pas encore testé | Le site ouvert depuis un smartphone, sur le réseau de l'école |
| **Analyse de trafic et de trames** | Absente | Capture pfSense lue dans Wireshark ; ntopng sur pfSense |
| **Contrat de service** | Proposé (DAT §14, DAT R1 §3), pas mesuré | Délais mesurés pendant les tests de R1 |
| **Chiffrement** | SSH seulement | Autorité interne de pfSense, HTTPS sur HAProxy (S5) |

## 5. Avant de partir

- [ ] Mon schéma correspond à ce que j'ai construit : presque, deux adresses restent à relever (HAProxy, WEB2)
- [x] Mon audit est rempli et mes **trois priorités** sont planifiées ([plan de reconstruction](../annexes/dat/plan-reconstruction.md))
- [x] Ma table de correspondance est faite
- [x] Mon DAT d'environnement est rédigé
- [ ] Mon journal est à jour
- [x] Mon dépôt est à jour
- [x] Je sais ce que je prépare avant la séance 4

## 6. Pour la séance 4 : mon besoin en 5 lignes

1. **Besoin de GSB** : l'application de suivi des visites doit rester accessible aux 480 visiteurs médicaux quand un serveur tombe.
2. **Données** : aucune visite ni note de frais validée ne doit être perdue.
3. **Évolution de mon laboratoire** : HTTPS sur le répartiteur, second HAProxy avec keepalived, bascules mesurées, plan de continuité.
4. **Résultat attendu** : arrêt d'un serveur web sans erreur visible ; bascule de la base en 15 s au plus ; bascule du répartiteur en 5 s au plus.
5. **À valider avec le formateur** : mission N3 avec le lot 3 en extension, et le plan de reconstruction du laboratoire.
