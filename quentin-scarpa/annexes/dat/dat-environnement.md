# DAT d'environnement

Version 1.0 · 29 octobre 2026 · Quentin Scarpa · Synthèse de l'existant, tirée du [DAT du laboratoire v1.4](dat-laboratoire.md)

Ce document décrit ce qui tourne aujourd'hui dans le laboratoire : c'est l'environnement exigé par l'annexe II.E, sur lequel s'appuient les deux réalisations. La cible (projet Sentinelle), le détail des choix et la feuille de route sont dans le [DAT complet](dat-laboratoire.md). Les valeurs marquées « à vérifier » ne sont pas encore relevées sur les machines (liste au [§18 du DAT](dat-laboratoire.md#18-points-à-vérifier)) ; le script `annexes/scripts/collecte-preuves.sh` les relève.

## 1. Architecture

![Vue d'ensemble : pfSense publie le site et isole quatre zones](../schemas/01-vue-ensemble.png)

- **Hébergement** : VM du cluster Proxmox VE de l'école, clonées d'une image Debian commune. Aucun équipement physique : les VLAN sont portés par le réseau virtuel de Proxmox.
- **Une seule porte** : pfSense route entre les quatre zones et vers le réseau de l'école (WAN `10.2.0.198`). Il n'autorise que les flux de la matrice et refuse le reste.
- **Chaîne web** : navigateur → pfSense (NAT 8081) → HAProxy → WEB1 ou WEB2 → HAProxy → grappe Galera (DB1, secours DB2 puis DB3).
- **Correspondance avec GSB** : [table de correspondance](correspondance-gsb.md).

## 2. Plan d'adressage

| VLAN | Zone | Réseau | Passerelle pfSense | Contenu | Adressage |
| --- | --- | --- | --- | --- | --- |
| 164 | WEB | 10.100.164.0/24 | .254 (à vérifier) | HAProxy, WEB1, WEB2 | Fixe |
| 165 | ADM | 10.100.165.0/24 | .254 (à vérifier) | ADPSQS | Fixe |
| 166 | BDD | 10.100.166.0/24 | .254 (à vérifier) | DB1, DB2, DB3 | Fixe |
| 167 | USERS | 10.100.167.0/24 | .254 (à vérifier) | Postes clients (à venir) | DHCP par ADPSQS (à venir) |
| WAN | École | Réseau de l'école | Passerelle de l'école | pfSense : 10.2.0.198 | Fixe |

Règle : adresses fixes de `.1` à `.99`, DHCP de `.100` à `.199`, passerelle en `.254`.

## 3. Machines en place

| Machine | ID Proxmox | Zone | Adresse | Système | Rôle |
| --- | --- | --- | --- | --- | --- |
| pfSense | 611 | WAN et 4 VLAN | 10.2.0.198 (WAN) | pfSense | Routage, filtrage, NAT, publication du site |
| ADPSQS | 606 | ADM | 10.100.165.1 | Windows Server 2022 | Active Directory (`qscarpa.lan`), DNS, DHCP |
| HAProxy | 616 | WEB | 10.100.164.2 (à vérifier) | Debian | Répartition HTTP, accès SQL vers Galera |
| WEB1 | 609 | WEB | 10.100.164.1 | Debian | Apache, PHP, WordPress |
| WEB2 | 615 | WEB | 10.100.164.3 (à vérifier) | Debian | Apache, PHP, WordPress |
| DB1 | 612 | BDD | 10.100.166.3 | Debian | MariaDB 10.11 et Galera, nœud principal |
| DB2 | 613 | BDD | 10.100.166.4 | Debian | MariaDB 10.11 et Galera, secours |
| DB3 | 614 | BDD | 10.100.166.5 | Debian | MariaDB 10.11 et Galera, secours |

Deux VM sont créées mais éteintes : 607 (future OPS : GLPI, bastion, Ansible) et 621 (rôle à préciser).

## 4. Flux en place

| N° | Source | Destination | Service | État |
| --- | --- | --- | --- | --- |
| F1 | Réseau de l'école | 10.2.0.198:8081, redirigé vers HAProxy:80 | HTTP, publication du site | En place |
| F2 | HAProxy | WEB1, WEB2 | HTTP, TCP 80 | En place |
| F3 | WEB1, WEB2 | HAProxy | MariaDB, TCP 3306 | À vérifier |
| F4, F5 | HAProxy | DB1, DB2, DB3 | TCP 3306 et contrôle de santé TCP 9200 | À vérifier |
| F6 | DB1, DB2, DB3 | Entre eux | Galera : TCP 4567, 4568, 4444, UDP 4567 | En place |
| F7 | Toutes les zones | ADPSQS | DNS, TCP et UDP 53 | À vérifier |
| F10 | Serveurs | Internet | HTTP et HTTPS, mises à jour | À vérifier |
| F11 | Poste d'administration | 10.2.0.198, ports 2222 à 2228 et 2253, redirigés vers SSH | Administration par clé | En place |
| F28 | Toute autre source | Toute destination | Refus par défaut, journalisé | À vérifier |

Matrice complète, avec les flux prévus F8 à F27 : [DAT §7](dat-laboratoire.md#7-réseau--zones-adressage-et-flux).

## 5. Choix justifiés

| Besoin | Retenu | Écarté | Pourquoi |
| --- | --- | --- | --- |
| Hyperviseur | Proxmox VE | Aucune alternative | Fourni par l'école, sauvegarde intégrée |
| Pare-feu | pfSense | OPNsense | Vu en cours, interface web, paquets comme Suricata ; OPNsense ferait aussi bien |
| Annuaire | Active Directory, Windows Server 2022 | Samba AD | Référence en entreprise, GPO natives, second système exigé par l'annexe II.E |
| Serveur web | Apache | Nginx | Compatible WordPress sans réglage (`.htaccess`), déjà maîtrisé |
| Base de données | MariaDB en grappe Galera, 3 nœuds | Réplication asynchrone | Aucune transaction validée perdue, bascule sans intervention |
| Répartition et accès SQL | HAProxy | DNS à tour de rôle, ProxySQL | Retire un serveur en panne, lit l'état Galera et pas seulement le port |

## 6. Sécurité et exploitation en place

- **Exposition** : un seul port publié pour le site (8081) ; la base n'est joignable que par HAProxy (à vérifier, test R1-T12).
- **Comptes** : compte WordPress limité à la base `wp2026` ; administration SSH par clé, mot de passe refusé.
- **Sauvegarde** : outil intégré de Proxmox (vzdump). Planning, conservation et restauration testée restent à faire.
- **Journaux** : sur chaque machine (`journalctl`, journaux Apache, journaux de pfSense), pas encore centralisés.
- **Démarrage** : VM éteintes entre les séances, ordre de démarrage et démarrage à froid de Galera documentés ([README des annexes](../README.md#démarrer-et-arrêter-le-laboratoire) et procédure 06).

## 7. Limites connues

- **Points uniques de défaillance** : pfSense, HAProxy (seconde instance prévue en R1, extension), ADPSQS.
- **Chiffrement** : le site est en HTTP ; HTTPS avec une autorité interne est prévu en R1.
- **Supervision** : aucune alerte automatique ; supervision prévue en R2.
- **Fichiers téléversés** : non partagés entre WEB1 et WEB2.
- **Couverture de l'annexe II.E** : 7 lignes sur 22 démontrables aujourd'hui, détail et priorités dans le [tableau de l'environnement](../../03-environnement-annexe-II-E.md).
