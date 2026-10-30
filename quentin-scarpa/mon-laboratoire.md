---
titre: "Mon laboratoire — la checklist de l'environnement (annexe II.E)"
tags: [eleves, u6, laboratoire, environnement, annexe-ii-e, checklist]
public: étudiants
---

# 🧱 Mon laboratoire — checklist de l'environnement

> **Pourquoi c'est important :** à l'épreuve, la commission vérifie que l'environnement de travail respecte l'**annexe II.E** du référentiel. Un environnement **non conforme** peut coûter **jusqu'à 15 points**. Une solution réduite à une **simulation** logicielle n'est pas acceptée.
> Retour : [[mon-parcours]] · Utilisée à partir de : [[vault/01-projets/clients/enseignement/aftec/projet-u6/eleves/seances/S03]] · Évaluation : [[ma-grille-e6]]

---

## 📋 L'outil officiel de la commission (annexe VII-7)

Cette checklist reprend, **ligne à ligne**, le tableau officiel que la commission utilise pour apprécier ton environnement (« Outil d'aide à l'appréciation de l'environnement technologique »).

| À savoir | |
|---|---|
| **Structure** | Un tableau à **trois colonnes** : l'élément exigé · la **description de son implantation** (nom de l'outil, caractéristiques techniques) · les **remarques de la commission** |
| **Contenu** | **26 lignes** : 8 pour l'environnement commun, 4 pour la sécurité, 10 spécifiques à SISR, plus **une solution au moins** parmi quatre |
| **Qui le remplit** | L'**établissement** décrit l'implantation ; la **commission** annote la dernière colonne pendant l'interrogation |
| **Rappels imprimés** | Les logiciels de simulation **ne remplacent pas** des équipements réels ; **une solution réduite à une simulation n'est pas acceptée** |
| **Pourquoi c'est joué** | Un élément déclaré que tu ne sais pas montrer peut être sanctionné : **jusqu'à −15 points** |

> **Ce que tu dois savoir faire :** pour chaque ligne, **expliquer l'outil** et **le montrer fonctionner**, ou dire clairement qu'il est fourni par l'école.

---

## 🧭 Comment l'utiliser

1. **Copie ce fichier** dans ton espace et remplis-le.
2. Pour chaque ligne, note **l'outil que tu utilises**, **qui le fournit** (l'école ou toi), et **la preuve** que tu peux montrer (capture, schéma, configuration).
3. **Ce n'est pas à toi seul de tout construire** : l'école fournit une partie de l'environnement. Ton rôle : **savoir ce qui existe, savoir le montrer et savoir expliquer ce que tu as construit toi-même**.
4. Repère ce qui **manque** et dis-le au formateur.

> ⚠️ **Une ligne que tu déclares mais que tu ne sais pas montrer est plus risquée qu'une ligne laissée vide.**

*Légende : ✅ présent et démontrable · 🟠 présent mais je ne sais pas encore le montrer · 🔴 absent*

---

*Checklist remplie par Quentin le 29 octobre 2026 (séance 3). Le tableau officiel est [`03-environnement-annexe-II-E.md`](03-environnement-annexe-II-E.md).*

## A. Les bases (8 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Idées d'outils | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|---|
| 1 | Un **service d'authentification** (annuaire) | Active Directory | Active Directory, Windows Server 2022 (ADPSQS), domaine `qscarpa.lan` ; pas encore d'OU, de groupes ni de GPO | moi | Procédure 04 ; `Get-ADDomain` à capturer | 🟠 |
| 2 | Une **base de données** | MariaDB, MySQL | MariaDB 10.11 en grappe Galera de 3 nœuds | moi | Procédure 06 ; état relevé par la collecte | ✅ |
| 3 | Un **accès sécurisé à Internet** | Pare-feu / NAT (pfSense) | pfSense : NAT sortant, filtrage par zone ; règles à vérifier | moi (pfSense), école (Internet) | Procédure 02 | 🟠 |
| 4 | Un **outil de travail collaboratif** | Nextcloud, Git, Mattermost | Git (dépôt GitHub du labo) ; Nextcloud prévu | moi | Historique des commits | ✅ |
| 5 | **Deux serveurs** sous **deux systèmes différents**, dont un open source | Debian + Windows Server | Windows Server 2022 et Debian | moi | DAT d'environnement §3 | ✅ |
| 6 | Une **sauvegarde** | BorgBackup, Proxmox Backup Server | vzdump de Proxmox ; ni planning ni restauration testée | école (Proxmox), moi | Procédure 01 §4.3 | 🟠 |
| 7 | Des **ressources à accès restreint** (habilitations) | Droits Active Directory, VPN | Compte WordPress limité à sa base ; SSH par clé ; statistiques HAProxy réservées à ADM | moi | Procédures 03, 06, 07 | 🟠 |
| 8 | **Deux types de terminaux** dont **un mobile** | Poste + smartphone ou tablette | Poste d'administration ; smartphone pas encore testé | moi | — | 🔴 |

## B. Les outils de sécurité (4 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Idées d'outils | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|---|
| 9 | La **gestion des incidents** | GLPI | GLPI prévu | — | — | 🔴 |
| 10 | La **détection / prévention d'intrusions** | Wazuh, Suricata | Suricata et Wazuh prévus | — | — | 🔴 |
| 11 | Le **chiffrement** | Certificats (autorité de certification), HTTPS, VPN | SSH par clé ; HTTPS avec autorité interne prévu (R1) | moi | Procédure 03 | 🟠 |
| 12 | L'**analyse de trafic** | Wireshark | Wireshark et ntopng prévus | — | — | 🔴 |

## C. Spécifique à SISR (10 lignes obligatoires)

| # | Ce que le laboratoire doit avoir | Idées d'outils | Mon outil | Fourni par | Preuve | État |
|---|---|---|---|---|---|---|
| 13 | Un réseau avec **plusieurs zones de sécurité** | VLAN + pare-feu | 4 VLAN (WEB, ADM, BDD, USERS) filtrés par pfSense | moi | Procédure 02, DAT §7 ; refus journalisé à capturer | 🟠 |
| 14 | Un **service rendu à l'utilisateur** avec un **contrat de service** (sécurité, disponibilité) | Un SLA écrit, des tests | Site haute disponibilité ; objectifs de reprise proposés, pas encore mesurés | moi | DAT R1 §3, plan de tests R1 | 🟠 |
| 15 | Un logiciel d'**analyse de trames** | Wireshark, tcpdump | Wireshark ou `tcpdump` prévus | — | — | 🔴 |
| 16 | Une **gestion des configurations** | Git, Ansible, GPO | Git ; configurations relevées par script ; Ansible prévu | moi | `annexes/scripts/` après la première collecte | 🟠 |
| 17 | Une **administration à distance sécurisée** | SSH, bastion (Guacamole), RDP | SSH par clé, mot de passe refusé ; bastion prévu | moi | Procédure 03 | ✅ |
| 18 | Une **supervision** avec **alertes** | Prometheus + Grafana, Zabbix | Aucune ; page d'état HAProxy sans alerte | — | — | 🔴 |
| 19 | Des **accès sécurisés** à un service (interne ou externe) | Reverse proxy HTTPS, VPN | HAProxy en mandataire inverse ; HTTPS prévu (R1) | moi | Procédure 07 | 🟠 |
| 20 | Une solution de **continuité** d'un service | Cluster de base de données, HAProxy | Grappe Galera, bascule SQL par HAProxy | moi | Procédures 06, 07, 08 | ✅ |
| 21 | Une **tolérance de panne** | CARP / VRRP, Proxmox HA | Deux Apache, trois nœuds Galera ; keepalived prévu (R1) | moi | Procédure 08 | ✅ |
| 22 | Une **répartition de charge** | HAProxy | HAProxy, tour de rôle entre WEB1 et WEB2 | moi | Procédure 07 | ✅ |

## D. Au moins **une** de ces quatre solutions

| # | Solution | Idées d'outils | Mon choix (oui/non) | Preuve | État |
|---|---|---|---|---|---|
| 23 | **Connexion sécurisée entre deux sites** | WireGuard, IPsec | non | — | 🔴 |
| 24 | **Déploiement** de solutions techniques d'accès | GPO, déploiement automatisé | non (GPO prévues) | — | 🔴 |
| 25 | Solution gérée par des **scripts** | Ansible, Bash, PowerShell | oui : PowerShell (annuaire), contrôle de santé Galera, scripts de collecte et de mesure ; Ansible prévu | Procédures 04 et 06, `annexes/scripts/` | 🟠 |
| 26 | **Détection d'intrusions** ou de comportements anormaux | Wazuh, Suricata | oui, prévue : Wazuh, Suricata | — | 🔴 |

---

## 📌 Mon bilan à la séance 3

- **Nombre de lignes ✅ :** 7 / 22 (2, 4, 5, 17, 20, 21, 22)
- **Lignes 🟠 (à apprendre à montrer) :** 9 (1, 3, 6, 7, 11, 13, 14, 16, 19)
- **Lignes 🔴 (absentes) :** 6 (8, 9, 10, 12, 15, 18)
- **La solution (23 à 26) que je vise :** 25 (scripts), puis 26 (détection d'intrusions)

**Les 3 lignes les plus urgentes à traiter :**
1. **Ligne 6, sauvegarde** : sauvegarder chaque VM et **restaurer** l'une d'elles (test T13).
2. **Ligne 18, supervision avec alertes** : Zabbix, avant S7.
3. **Lignes 11 et 19, chiffrement** : autorité interne et HTTPS sur HAProxy, exigés aussi par R1.

**Gains rapides, moins d'une heure chacun :** ouvrir le site sur un smartphone (ligne 8) ; une capture commentée du trafic entre HAProxy et DB1 (lignes 12 et 15) ; capture des règles pfSense et d'un refus journalisé (ligne 13) ; première collecte de preuves (lignes 2, 16, 17, 20 à 22).

*Tu mettras cette checklist à jour à la séance 10, puis une dernière fois à la séance 14.*
