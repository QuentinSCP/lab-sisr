# Plan de reconstruction du laboratoire

Version 1.0 · 29 octobre 2026 · Quentin Scarpa · À valider avec le formateur en S4

Ce plan reconstruit tout le laboratoire, proprement et de façon rejouable, **sans changer l'infrastructure, l'adressage ni la segmentation** : cluster Proxmox de l'école, pfSense, quatre VLAN (164 à 167), mêmes adresses, même domaine `qscarpa.lan`. Il vise la conformité complète à l'annexe II.E du référentiel et porte les deux réalisations : R1 (mission N3, haute disponibilité) et R2 (mission N4, supervision). S'il est validé, il remplace la feuille de route du [DAT §17](../quentin-scarpa/annexes/dat/dat-laboratoire.md#17-feuille-de-route).

> **À valider avant de commencer.** En S3, le formateur demande d'auditer et de compléter le laboratoire, pas de le reconstruire, et les conventions GSB présentent chaque mission comme une évolution de l'existant. La reconstruction se défend : versions de Debian non homogènes, valeurs jamais relevées sur les machines, mot de passe de test à remplacer, et surtout la rejouabilité exigée en phase 2 de l'épreuve. Mais elle doit être acceptée en S4, avant toute destruction.

## 1. Ce que le référentiel national exige

Source : référentiel du BTS SIO, annexe II.E « Environnement technologique pour la certification ». Le référentiel n'impose **aucune architecture ni aucun outil** : il impose des fonctions. Le contexte GSB est le choix pédagogique du formateur.

Quatre précisions du texte officiel comptent pour la reconstruction :

- l'authentification concerne les utilisateurs **internes et externes** à l'organisation ;
- l'administration à distance porte sur les serveurs **et** sur les solutions techniques d'accès, c'est-à-dire les postes ;
- la supervision couvre aussi les **équipements d'interconnexion** (pfSense) et doit faire remonter des alertes ;
- le contrat de service comporte des contraintes de **sécurité et de haute disponibilité**.

Deux règles générales : une solution d'infrastructure réduite à une simulation n'est pas acceptée ; le recours au cloud est recommandé.

**L'épreuve** (même référentiel) : deux réalisations qui, ensemble, mobilisent toutes les compétences du bloc. Phase 1 : 30 min de préparation et 20 min d'entretien sur une expression de besoins tirée d'une des réalisations. Phase 2 : 1 h pour réaliser la solution « en ayant recours à l'environnement de travail disponible dans le centre d'interrogation », puis 20 min de recette. Le candidat est « seul responsable de la disponibilité et de la mise en œuvre » de ses outils : le labo doit démarrer de façon fiable le jour de l'épreuve. Le référentiel numérote cette épreuve E5 ; les documents de la session 2026 et le formateur l'appellent E6 : c'est la même épreuve.

### Exigences et solutions retenues

| # | Exigence de l'annexe II.E | Solution dans le labo reconstruit | Machines | Phase |
| --- | --- | --- | --- | --- |
| 1 | Service d'authentification des utilisateurs internes et externes | Active Directory `qscarpa.lan` : OU des internes et OU des externes ; LDAPS pour Nextcloud, GLPI et le bastion ; les externes n'accèdent qu'à l'extranet Nextcloud | ADPSQS, COLLAB | 2, 9 |
| 2 | SGBD | MariaDB en grappe Galera de 3 nœuds | DB1 à DB3 | 4 |
| 3 | Accès sécurisé à Internet | pfSense : NAT sortant limité (HTTP, HTTPS, DNS, NTP), refus par défaut journalisé ; Suricata sur le WAN | pfSense | 1, 10 |
| 4 | Environnement de travail collaboratif | Nextcloud (fichiers, agenda, discussions) lié à l'annuaire ; Git pour l'équipe technique | COLLAB | 9 |
| 5 | Deux serveurs sur des OS différents, dont un open source | Windows Server (ADPSQS) et Debian (toutes les autres machines) | Toutes | 2, 3 |
| 6 | Solution de sauvegarde | vzdump planifié et BorgBackup (exports SQL, configurations, données des outils), restaurations testées | Proxmox, SAUVEGARDE | 0, 6 |
| 7 | Ressources à accès sécurisé et soumis à habilitation | Groupes AD selon le modèle AGDLP : partages SMB, dossiers Nextcloud, profils GLPI, connexions du bastion | ADPSQS, COLLAB, OPS | 2, 9, 11 |
| 8 | Deux types de terminaux dont un mobile | Poste Windows 11 joint au domaine ; smartphone (Nextcloud et application) | Poste client | 9 |
| 9 | Gestion des incidents | GLPI : tickets, inventaire, ticket ouvert par la supervision | OPS | 8 |
| 10 | Détection et prévention des intrusions | Suricata sur pfSense ; Wazuh avec réponse active (blocage temporaire) | pfSense, SIEM | 10 |
| 11 | Chiffrement | Autorité de certification interne (pfSense) : HTTPS, LDAPS ; SSH par clé ; sauvegardes chiffrées | Toutes | 1, 2, 5, 6 |
| 12 | Analyse de trafic | ntopng sur pfSense : flux par machine et par protocole | pfSense | 10 |
| 13 | Réseau à plusieurs périmètres de sécurité | 4 VLAN (WEB, ADM, BDD, USERS) filtrés par pfSense | pfSense | 1 |
| 14 | Service rendu selon un contrat de service (sécurité, haute disponibilité) | Application de suivi des visites en HTTPS, haute disponibilité ; contrat de service mesuré (rapport SLA) | Chaîne web, MON | 5, 8 |
| 15 | Logiciel d'analyse de trames | Wireshark sur le poste client et le poste d'administration, captures pfSense et `tcpdump` | Poste client | 7, 9 |
| 16 | Logiciel de gestion des configurations | Git et Ansible (Linux), scripts PowerShell (Windows), inventaire GLPI | OPS | 3, 8 |
| 17 | Administration à distance sécurisée des serveurs et des postes | SSH par clé avec rebond par OPS ; bastion Guacamole (double authentification, sessions enregistrées) : SSH vers les serveurs, RDP vers ADPSQS et le poste | OPS | 3, 11 |
| 18 | Supervision de la qualité, de la sécurité et de la disponibilité, avec remontée d'alertes | Zabbix : pfSense (SNMP), serveurs, services ; alertes graduées, escalade, ticket GLPI ; alertes de sécurité de Wazuh | MON, SIEM | 8, 10 |
| 19 | Accès sécurisés à un service interne (intranet) ou externe (extranet, Internet) | Application publiée en HTTPS par HAProxy ; extranet Nextcloud en HTTPS pour les externes | HAProxy, COLLAB | 5, 9 |
| 20 | Continuité d'un service | Grappe Galera et bascule SQL ; sauvegardes restaurées | DB1 à DB3, HAProxy | 4, 6 |
| 21 | Tolérance de panne de serveurs ou d'éléments d'interconnexion | Deux Apache, trois nœuds Galera, deux HAProxy avec keepalived (adresse virtuelle) | WEB, BDD | 5 |
| 22 | Répartition de charges | HAProxy, tour de rôle entre WEB1 et WEB2 | HAProxy | 5 |
| 23 | Connexion sécurisée entre deux sites | Non retenue | — | — |
| 24 | Déploiement des solutions techniques d'accès | En option : déploiement par GPO (certificat de l'autorité, agents) | ADPSQS | 9 |
| 25 | Solution gérée par procédures automatisées (scripts) | **Retenue** : Ansible, PowerShell, scripts shell | OPS | 2 à 12 |
| 26 | Détection d'intrusions ou de comportements anormaux | **Retenue** : Suricata et Wazuh | pfSense, SIEM | 10 |

Les lignes 1 à 22 sont obligatoires ; pour les lignes 23 à 26, une seule suffit, ce plan en couvre deux.

## 2. Ce qui ne change pas, ce qui change

**Inchangé** : cluster Proxmox de l'école, pfSense seule porte entre les zones, WAN `10.2.0.198`, domaine `qscarpa.lan`, et le plan d'adressage : adresses fixes de `.1` à `.99`, DHCP de `.100` à `.199`, passerelle pfSense en `.254`.

| VLAN | Zone | Réseau | Machines |
| --- | --- | --- | --- |
| 164 | WEB | 10.100.164.0/24 | WEB1 .1, HAProxy .2, WEB2 .3, HAProxy2 .4, adresse virtuelle du site .10 |
| 165 | ADM | 10.100.165.0/24 | ADPSQS .1, OPS .10, MON .11, SIEM .12, COLLAB .14, SAUVEGARDE .15 |
| 166 | BDD | 10.100.166.0/24 | DB1 .3, DB2 .4, DB3 .5 |
| 167 | USERS | 10.100.167.0/24 | Postes, DHCP de .100 à .199 |

**Inventaire cible et ressources** (à faire valider par l'école)

| Machine | ID actuel | Adresse | Système | vCPU | Mémoire | Disque | Rôle | Phase |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| pfSense | 611 | 10.2.0.198, .254 par VLAN | pfSense CE | 2 | 4 Go | 20 Go | Pare-feu, NAT, autorité interne, Suricata, ntopng, NTP | 1 |
| ADPSQS | 606 | 10.100.165.1 | Windows Server | 2 | 4 Go | 60 Go | AD DS, DNS, DHCP, LDAPS, partages | 2 |
| OPS | 607 | 10.100.165.10 | Debian | 2 | 4 Go | 40 Go | Ansible, rebond SSH, GLPI, Guacamole | 3, 8, 11 |
| MON | à créer | 10.100.165.11 | Debian | 2 | 4 Go | 40 Go | Zabbix | 8 |
| SIEM | à créer | 10.100.165.12 | Debian | 4 | 8 Go | 100 Go | Wazuh | 10 |
| COLLAB | à créer | 10.100.165.14 | Debian | 2 | 4 Go | 40 Go | Nextcloud | 9 |
| SAUVEGARDE | à créer | 10.100.165.15 | Debian | 1 | 2 Go | 200 Go | BorgBackup | 6 |
| HAProxy | 616 | 10.100.164.2 | Debian | 1 | 1 Go | 10 Go | Répartiteur principal | 5 |
| HAProxy2 | à créer | 10.100.164.4 | Debian | 1 | 1 Go | 10 Go | Répartiteur de secours | 5 |
| WEB1, WEB2 (chacun) | 609, 615 | 10.100.164.1 et .3 | Debian | 2 | 2 Go | 20 Go | Apache, PHP, application | 5 |
| DB1, DB2, DB3 (chacun) | 612 à 614 | 10.100.166.3 à .5 | Debian | 2 | 2 Go | 20 Go | MariaDB et Galera | 4 |
| Poste client | à créer | DHCP | Windows 11 | 2 | 4 Go | 64 Go | Poste du domaine, Wireshark | 9 |
| **Total** | | | | **29** | **46 Go** | **684 Go** | | |

SIEM (8 Go) et COLLAB peuvent rester éteintes hors usage. La VM 621 est à identifier puis à supprimer si elle ne sert pas.

**Ce qui change** (proposé, décisions D5 et D1 à D3) :

- **Administration** : une seule entrée SSH, `10.2.0.198:2224` vers OPS, ouverte au seul poste d'administration ; les serveurs se joignent par rebond (`ssh -J ops web1`). Les redirections 2222, 2223, 2225 à 2228 et 2253 disparaissent.
- **Publications** : 8081 (HTTP, redirigé vers HTTPS) et 8444 (HTTPS) vers l'adresse virtuelle du site ; 8443 vers le bastion et 8082 vers Nextcloud quand ils existent.
- **Systèmes** : une seule version de Debian et une seule version de chaque logiciel sur toutes les machines.

## 3. Décisions à prendre avant la phase 1

| N° | Question | Recommandation | Raison |
| --- | --- | --- | --- |
| D1 | Version de Debian | Debian 13, version stable actuelle | Debian 12 n'a plus que le support à long terme (LTS) depuis juin 2026. Avant de trancher : vérifier que l'application de référence fonctionne avec PHP 8.4 et que Zabbix et Wazuh publient leurs paquets pour Debian 13. Sinon, Debian 12 pour les machines concernées |
| D2 | Version de Windows | Celle fournie par l'école ; Windows 11 pour le poste | Windows Server 2022 n'a plus que le support étendu depuis le 13 octobre 2026 ; Windows 10 n'est plus supporté depuis octobre 2025. Une licence d'évaluation dure 180 jours (90 pour Windows 11) : noter sa date de fin, l'épreuve a lieu en mai ou juin 2027 |
| D3 | Outil de supervision | Zabbix, dernière version LTS | Voir le comparatif ci-dessous. Le DAT v1.4 retenait Prometheus : ce comparatif sert aussi de dossier de choix pour R2 |
| D4 | Sauvegarde | vzdump planifié et BorgBackup sur SAUVEGARDE | Proxmox Backup Server suppose que les nœuds Proxmox de l'école joignent la zone ADM (flux F22, inconnu). Borg reste à l'intérieur du labo |
| D5 | Accès d'administration | Rebond par OPS dès la phase 3 | Un seul port d'administration exposé au lieu de huit ; la connexion part de la zone ADM, comme l'exige R1 (résultat attendu 6) |
| D6 | Charge de travail de R1 | Application de référence du formateur | WordPress seulement si le code n'arrive pas à temps |
| D7 | Bases de données des outils (GLPI, Zabbix, Nextcloud) | Locales à chaque outil | La grappe reste dédiée à l'application ; un outil d'exploitation ne doit pas dépendre du système qu'il surveille |
| D8 | Serveur de fichiers FS01 | Non retenu | Partages SMB sur ADPSQS et Nextcloud suffisent à la ligne 7 ; économise une licence et 4 Go |
| D9 | Identifiants des VM | Nouveaux ID si l'école en attribue | L'ancienne VM, arrêtée, sert de retour arrière immédiat ; sinon, réutiliser les ID après la sauvegarde de la phase 0 |

**Comparatif de la décision D3**

| Besoin (mission N4, annexe II.E) | Zabbix | Prometheus, Grafana et Alertmanager |
| --- | --- | --- |
| Composants | Un serveur, une interface web, des agents | Trois services, plus un exporter par type de source |
| pfSense | Modèle SNMP fourni | `snmp_exporter` à configurer |
| Contrat de service | Services et rapports SLA intégrés | Calcul à écrire en PromQL |
| Escalade (N4, lot 3) | Étapes d'escalade dans les actions | Routage et répétition, sans étapes dans le temps |
| Ticket GLPI | Webhook GLPI fourni (vérifier sa compatibilité avec la version de GLPI) | Script relais à écrire |
| Tableaux de bord | Corrects | Plus visuels (Grafana) |

**Hors périmètre**, à ne faire que s'il reste du temps : l'assistant IA, le VPN entre deux sites (ligne 23), une paire CARP pour pfSense, une zone Visiteurs (elle changerait la segmentation ; seulement si l'extension de N4 est demandée).

## 4. Principes

1. **Rien n'est détruit avant que son remplaçant soit validé.** L'ancienne VM est arrêtée et sauvegardée (phase 0). Comme l'adressage ne change pas, une ancienne VM restaurée reprend sa place dans le nouveau réseau.
2. **Tout est scripté.** Chaque machine Linux sort du même gabarit et d'un playbook Ansible ; ADPSQS sort de scripts PowerShell. Un réglage fait à la main est reporté dans un script le jour même.
3. **Aucun secret dans Git.** Les secrets sont chiffrés avec Ansible Vault et le fichier chiffré reste hors du dépôt, sauvegardé par Borg ; seul un modèle sans valeurs (`vault.exemple.yml`) est versionné. L'export de pfSense est chiffré et hors dépôt.
4. **Chaque phase se termine par une preuve** : un critère vérifiable, une collecte (`annexes/scripts/collecte-preuves.sh`, qui passe par le rebond sans changement), un commit. Les procédures sont mises à jour dans la même phase.
5. **L'ordre suit les dépendances** : réseau, noms (DNS), poste de commande, données, web, puis exploitation et sécurité.

## 5. Les phases

### Phase 0 · Geler et sauvegarder l'existant

D'ici S4 (6 novembre) · ≈ 3 h · Ligne 6

1. Faire valider le plan et demander à l'école : les ressources du §2, une plage d'ID de VM, les droits (gabarits, cloud-init, stockage de sauvegarde), l'accès au labo pendant le stage, les ISO et licences Windows, un relais de messagerie pour les alertes, le code de l'application de référence.
2. Relever l'état actuel : `annexes/scripts/collecte-preuves.sh`, captures de pfSense (interfaces, règles, NAT), export chiffré de sa configuration, hors dépôt.
3. Exporter les données : `mariadb-dump --all-databases --single-transaction` sur DB3, copié hors du labo et hors dépôt.
4. Sauvegarder chaque VM avec vzdump (606, 607, 609, 611 à 616, 621). Restaurer l'une d'elles vers un ID libre, carte réseau débranchée, et la démarrer : première preuve de la ligne 6 (test T13).
5. Poser l'étiquette Git `labo-v1`, état de référence avant reconstruction, et noter les décisions D1 à D9 dans ce plan.

**Critère de sortie** : chaque VM a une sauvegarde datée ; une restauration a démarré ; les décisions sont prises.

### Phase 1 · Réseau : pfSense neuf

S4 · ≈ 3 h · Lignes 3, 11, 13 · Procédure 02 à mettre à jour

1. Installer pfSense CE, dernière version stable : carte WAN sur le réseau de l'école (`10.2.0.198`), carte interne sans étiquette VLAN ; décocher « Block private networks » sur le WAN.
2. Créer les VLAN 164 à 167 et leurs passerelles en `.254` (procédure 02 §4.1) ; nom `pfsense.qscarpa.lan`, fuseau Europe/Paris, service NTP sur les interfaces internes.
3. Autorité interne : **System > Cert. Manager**, autorité `QSCARPA-CA`, puis le certificat de l'interface web. Le certificat **public** de l'autorité est versionné (`annexes/scripts/pki/qscarpa-ca.crt`), jamais sa clé.
4. Alias : `HAPROXY` (.2 et .4), `VIP_SITE` (.10), `WEB_SERVERS`, `DB_NODES`, `ADPSQS`, `OPS`, `MON`, `SIEM`, `COLLAB`, `SAUVEGARDE`, `ADMIN_PC`, et les groupes de ports (`PORTS_AD`, `PORTS_SQL_CHECK`, `PORTS_ZABBIX`, `PORTS_WAZUH`).
5. Règles tirées de la matrice des flux (DAT §7), chacune décrite par son numéro de flux ; refus par défaut journalisé. La matrice évolue : F11 devient l'entrée unique vers OPS, F14 sert aux agents Zabbix et au SNMP, F16 disparaît (bases locales, D7), F29 est ajouté pour Borg (vers SAUVEGARDE, TCP 22).
6. NAT : 8081 et 8444 vers `VIP_SITE` (ports 80 et 443) ; 2224 vers OPS (port 22), source `ADMIN_PC` seulement ; sortie limitée à HTTP, HTTPS, DNS et NTP.
7. Exporter la configuration, chiffrée et hors dépôt, à chaque fin de séance.

**Critère de sortie** : les cinq interfaces répondent ; chaque règle porte son numéro de flux ; un flux non prévu apparaît refusé dans le journal (vérifié depuis ADPSQS en phase 2).
**Retour arrière** : arrêter la nouvelle VM, redémarrer l'ancienne.

### Phase 2 · Annuaire : ADPSQS par scripts

S4 et S5 · ≈ 4 h · Lignes 1, 5, 7, 11 · Procédure 04 à mettre à jour · Scripts dans `annexes/scripts/ad/`

1. `01-base.ps1` : nom, adresse `10.100.165.1/24`, passerelle `.254`, DNS `127.0.0.1`, fuseau.
2. `02-foret.ps1` : rôles AD DS, DNS et DHCP ; forêt `qscarpa.lan`. Le mot de passe de restauration (DSRM) est saisi, jamais écrit.
3. `03-dns.ps1` : redirecteur vers le DNS de l'école ; zones inverses des quatre VLAN ; enregistrements A et PTR de toutes les machines depuis une seule table (celle du §2) ; `visite.qscarpa.lan` vers `10.100.164.10` ; alias `glpi`, `bastion`, `zabbix`, `cloud`.
4. `04-dhcp.ps1` : étendue USERS de `.100` à `.199` (passerelle `.254`, DNS `.1`, domaine) ; relais DHCP activé sur pfSense.
5. `05-annuaire.ps1` : OU `GSB` (internes par service, externes, groupes, postes, serveurs, comptes de service, administrateurs) ; un groupe global par service et un groupe local par ressource (AGDLP) ; comptes **fictifs** lus dans `annexes/scripts/ad/utilisateurs.csv` ; comptes de service LDAP en lecture seule ; un compte d'administration distinct du compte courant.
6. `06-gpo.ps1` : mot de passe et verrouillage du domaine ; GPO des postes (verrouillage de session, certificat de l'autorité dans les racines de confiance, pare-feu Windows) ; lecteurs réseau par service.
7. LDAPS : demande de certificat (`certreq`, nom `adpsqs.qscarpa.lan`) signée par `QSCARPA-CA`, importée dans le magasin de l'ordinateur.
8. Heure synchronisée sur pfSense (`10.100.165.254`) ; partages SMB par service sur ADPSQS (D8), droits accordés aux groupes locaux.

**Critère de sortie** : `dcdiag /q` sans erreur ; résolution directe et inverse correcte pour chaque machine ; `openssl s_client -connect adpsqs.qscarpa.lan:636` présente la chaîne de `QSCARPA-CA` ; un flux non prévu depuis ADPSQS est refusé et journalisé par pfSense.

### Phase 3 · Gabarit Debian et poste de commande OPS

S5 · ≈ 4 h · Lignes 16, 17, 25 · Procédures 01 et 03 à mettre à jour, 09 (Ansible) à écrire

1. **Gabarit** : Debian minimale (D1), `qemu-guest-agent`, `sudo`, cloud-init si l'école l'autorise, converti en modèle Proxmox. Sans cloud-init : procédure 01 §4.1 (identité de la machine, clés SSH).
2. **OPS** (`10.100.165.10`) cloné du gabarit : Git, Ansible, clone du dépôt. Sa clé SSH ed25519 devient la clé d'administration des serveurs.
3. **Poste d'administration** : `~/.ssh/config` avec `ops` (`10.2.0.198`, port 2224), puis chaque serveur en `ProxyJump ops`.
4. **`annexes/scripts/ansible/`** : `inventaire.ini` (groupes haproxy, web, galera, outils) ; `group_vars/all.yml` (domaine, DNS, NTP) ; `socle.yml` : paquets de base, fuseau, chrony vers la passerelle `.254`, DNS vers ADPSQS, durcissement SSH (procédure 03 §4.4), mises à jour de sécurité automatiques, certificat de l'autorité, taille maximale du journal.
5. **Secrets** : `ansible-vault` (principe 3).

**Critère de sortie** : `ssh web1` passe par OPS sans mot de passe ; `socle.yml` s'applique sans erreur, puis une seconde fois sans aucun changement.

### Phase 4 · Données : grappe Galera

S5 · ≈ 3 h · Lignes 2, 20 · Procédure 06 à mettre à jour · `annexes/scripts/ansible/galera.yml`

1. Cloner DB1, DB2 et DB3 (`.3`, `.4`, `.5`) ; appliquer `socle.yml` puis `galera.yml` : paquets, `60-galera.cnf` généré pour chaque nœud, contrôle de santé du port 9200 (procédure 06 §4.4), export logique quotidien sur DB3.
2. Amorcer DB1 à la main (`galera_new_cluster`), puis démarrer DB2 et DB3 un par un (procédure 06 §4.3).
3. Créer la base de l'application (script du formateur). Les comptes sont créés pour `10.100.164.2` **et** `10.100.164.4`, les deux répartiteurs ; le compte du contrôle de santé n'a aucun privilège. Avant l'import, vérifier InnoDB et les clés primaires (procédure 06 §4.5) : un ancien script SQL peut créer des tables MyISAM.
4. N'importer les données de la phase 0 que si elles servent encore (D6).

**Critère de sortie** : `wsrep_cluster_size` vaut 3, tous les nœuds sont `Synced` ; le port 9200 répond 200 sur les trois nœuds ; une base créée sur DB1 apparaît sur DB3 ; un arrêt complet suivi d'un démarrage à froid réussit (procédure 06 §5).

### Phase 5 · Chaîne web haute disponibilité (R1)

S6 · ≈ 6 h · Lignes 11, 14, 19, 20, 21, 22 · Procédures 05 et 07 à mettre à jour, 10 (HTTPS et keepalived) à écrire · `annexes/scripts/ansible/web.yml`, `annexes/scripts/ansible/haproxy.yml`

1. **WEB1 (`.1`) et WEB2 (`.3`)** : Apache, PHP, application de référence déployée sans modification, base jointe par l'adresse virtuelle ; en-tête `X-Served-By` ; adresse réelle du client (`remoteip`, confiance accordée à `.2` et `.4`).
2. **HAProxy (`.2`) et HAProxy2 (`.4`)**, avec le **même** `haproxy.cfg` généré par Ansible :
   - HTTPS avec un certificat de `QSCARPA-CA` portant `10.2.0.198`, `10.100.164.10` et `visite.qscarpa.lan` ;
   - redirection de HTTP vers HTTPS, écrite pour l'adresse publique et pour l'adresse interne ;
   - `option redispatch`, et l'affinité de session si l'application l'exige ;
   - accès SQL avec le contrôle du port 9200 et `on-marked-up shutdown-backup-sessions` ;
   - page de statistiques réservée à la zone ADM.
3. **keepalived** : adresse virtuelle `10.100.164.10`, HAProxy prioritaire, contrôle de l'état du service HAProxy, `net.ipv4.ip_nonlocal_bind=1` sur les deux instances.
4. **Vérifier avec l'école** que le pare-feu de Proxmox ne filtre pas les adresses IP des VM (option « IP filter ») : il bloquerait l'adresse virtuelle.
5. **pfSense** : NAT 8081 et 8444 vers l'adresse virtuelle.

**Critère de sortie** : tests R1-T01 à R1-T05 et R1-T13 du [plan de tests R1](../quentin-scarpa/annexes/tests/plan-de-tests-r1.md) réussis.

### Phase 6 · Sauvegarde et restauration

S6, ou pendant le stage · ≈ 3 h · Lignes 6, 20 · Procédure 11 à écrire · `annexes/scripts/ansible/sauvegarde.yml`

1. vzdump planifié chaque nuit vers le stockage de l'école, 7 jours de conservation, si les droits le permettent.
2. **SAUVEGARDE** (`10.100.165.15`) : dépôts BorgBackup chiffrés. Chaque source pousse en mode « ajout seul » : une machine compromise ne peut pas effacer ses sauvegardes. Sources : exports SQL de DB3, `/etc` de chaque serveur, configuration de pfSense, fichier Vault, données de GLPI et de Nextcloud quand ils existent.
3. Restaurations chronométrées : une VM depuis vzdump (T13), la base `recette` depuis l'export (R1-T15), un fichier de configuration depuis Borg.
4. Option recommandée par le référentiel (cloud) : copie chiffrée des dépôts Borg chez un hébergeur situé dans l'Union européenne (RGPD).

**Critère de sortie** : trois restaurations réussies, délais notés et comparés aux objectifs du [DAT R1 §3](../quentin-scarpa/annexes/dat/dat-r1.md#3-objectifs-de-continuité).

### Phase 7 · Recette de R1 et preuves

S6, puis S7 (8 janvier) · ≈ 4 h · Lignes 14, 15

1. Dérouler le [plan de tests R1](../quentin-scarpa/annexes/tests/plan-de-tests-r1.md) avec `annexes/scripts/mesure-bascule.sh` ; remplir le tableau des pannes.
2. Capture de trames : capture pfSense (**Diagnostics > Packet Capture**) pendant une connexion HTTPS et une bascule SQL, lue dans Wireshark sur le poste d'administration et commentée couche par couche.
3. Collecte des preuves, captures d'écran, rapport de tests.
4. S7 : exercice d'incident conduit par le formateur, puis rapport d'incident.

**Critère de sortie** : tableau des pannes rempli, rapport de tests rédigé.

### Phase 8 · Supervision et gestion des incidents (R2, mission N4)

S7 et S8, fin en S11 · ≈ 8 h · Lignes 9, 14, 16, 18 · Procédures 12 (Zabbix) et 13 (GLPI) à écrire · `annexes/scripts/ansible/agents.yml`

1. **MON** (`10.100.165.11`) : Zabbix (D3), base locale, interface en HTTPS.
2. **Sources** : agent Zabbix 2 sur chaque Debian, déployé par Ansible (le « déploiement par script » exigé par N4) ; sur ADPSQS par script PowerShell ; pfSense par SNMP ; contrôles de service : site par l'adresse virtuelle et par le NAT, DNS d'ADPSQS, MariaDB, HAProxy, validité des certificats.
3. **Contrat de service** : service « Application de suivi des visites », objectif de disponibilité, rapport SLA.
4. **Alertes** : niveaux de gravité, envoi par mail (relais à obtenir), escalade en étapes : le technicien d'abord, le responsable si l'alerte dure.
5. **GLPI sur OPS** (base locale, D7) : authentification LDAPS, inventaire par l'agent GLPI, ticket ouvert par le webhook GLPI de Zabbix.
6. Procédure d'escalade, mode dégradé, exercice d'incident de R2 en S13.

**Critère de sortie** : l'arrêt de MariaDB sur DB1 déclenche, en moins de 2 minutes, une alerte de bonne gravité, un mail et un ticket GLPI ; le rapport SLA s'affiche.

### Phase 9 · Poste, mobile et collaboratif

S9 (5 février) · ≈ 6 h · Lignes 1, 4, 7, 8, 15, 19, 24 · Procédures 14 (poste et GPO) et 15 (Nextcloud) à écrire

1. **Poste Windows 11** (USERS, DHCP) : TPM virtuel et UEFI dans Proxmox ; joint au domaine, GPO vérifiées (`gpresult /r`) ; Wireshark ; agents Zabbix, Wazuh et GLPI installés par script ou par GPO (ligne 24, en option).
2. **COLLAB** (`10.100.165.14`) : Nextcloud, base locale, HTTPS ; comptes AD par LDAPS. Les internes accèdent à leurs dossiers de groupe ; les externes de l'OU dédiée ne voient que les partages qui leur sont ouverts. Publication par le NAT 8082 : c'est l'extranet.
3. **Smartphone** : application Nextcloud, puis l'application de suivi en HTTPS, certificat de l'autorité accepté ou installé.

**Critère de sortie** : un utilisateur interne ouvre une session sur le poste et retrouve son lecteur réseau ; un compte externe se connecte depuis le smartphone et ne voit que son partage.

### Phase 10 · Journaux et détection

S10 (19 février) · ≈ 6 h · Lignes 3, 10, 12, 18, 26 · Procédure 16 à écrire

1. **SIEM** (`10.100.165.12`) : Wazuh tout-en-un, interface en HTTPS ; agents par Ansible et par script sur Windows.
2. **pfSense** : Suricata en détection sur le WAN et la zone WEB, alertes envoyées à Wazuh par syslog ; ntopng pour l'analyse de trafic.
3. **Réponse active** : blocage temporaire après une force brute SSH (règle 5763), avec OPS et le poste d'administration en liste blanche ; contrôle d'intégrité des fichiers de configuration de l'application et de `/etc`.
4. Scénarios S1 à S3 du [DAT §16](../quentin-scarpa/annexes/dat/dat-laboratoire.md#16-sentinelle--exploitation-et-sécurité), joués depuis le poste client.

**Critère de sortie** : une force brute est bloquée et visible dans Wazuh ; un balayage de ports déclenche une alerte Suricata, expliquée avec une capture.

### Phase 11 · Bastion

S11 (5 mars) · ≈ 4 h · Lignes 7, 17 · Procédure 17 à écrire

1. **Guacamole sur OPS** (conteneurs), en HTTPS, publié par le NAT 8443 : authentification LDAPS réservée au groupe des administrateurs, double authentification TOTP, sessions enregistrées.
2. **Connexions** : SSH vers chaque serveur, RDP vers ADPSQS et vers le poste : la ligne 17 couvre ainsi les serveurs **et** les postes.
3. **pfSense** : SSH et RDP vers les serveurs n'acceptent plus que OPS (F25) ; l'entrée 2224 reste, limitée au poste d'administration, comme accès de secours avec la console Proxmox.

**Critère de sortie** : une session d'administration complète passe par le bastion, elle est enregistrée et rejouable ; une connexion directe est refusée.

### Phase 12 · Rejouer, chronométrer, geler

S12 à S14 (18 au 26 mars) · ≈ 4 h

1. **Reconstruction chronométrée** : détruire WEB2 ou un nœud Galera, le recréer depuis le gabarit et Ansible, le réintégrer ; objectif 30 min. Puis toute la chaîne R1 depuis zéro.
2. **Répétitions d'évolutions en 1 h** pour chaque réalisation. Exemples : ajouter WEB3, passer en `leastconn`, activer l'affinité de session, publier un second service en HTTPS ; superviser un nouveau service, ajouter une alerte ou une étape d'escalade, restaurer une sauvegarde.
3. **Script de vérification** de bout en bout pour le jour de l'épreuve : grappe à 3, serveurs HAProxy `UP`, adresse virtuelle présente, site en 200 par le NAT, aucune alerte Zabbix ouverte.
4. **Documents** : DAT v2.0 conforme à ce qui tourne, annexe II.E définitive, fiches R1 et R2, étiquette Git `dossier-2027`.

**Critère de sortie** : une machine reconstruite en moins de 30 min ; une évolution de chaque réalisation faite en moins d'1 h.

## 6. Calendrier

| Période | Séances | Phases | Jalon |
| --- | --- | --- | --- |
| D'ici le 5 novembre | — | 0 | Plan validé, sauvegardes, restauration testée, décisions prises |
| 6 novembre | S4 | 1, 2 | pfSense et annuaire neufs ; DAT R1 revu |
| 12 et 13 novembre | S5, S6 | 3, 4, 5 | Chaîne R1 reconstruite ; point d'étape J1 |
| 17 au 20 novembre | BTS blanc | — | Aucun changement sur le labo |
| Stage, de novembre à janvier | — | 6, 7 | Seulement si le labo est accessible à distance |
| 8 janvier | S7 | 7, 8 | Exercice d'incident R1 ; supervision lancée |
| 14 janvier | S8 | 8 | Fiche R1 finalisée |
| 5 février | S9 | 9 | Poste, mobile, Nextcloud ; point d'étape J2 |
| 19 février | S10 | 10 | Wazuh, Suricata, ntopng ; DAT R2 |
| 5 mars | S11 | 11, fin de 8 | Bastion ; R2 complète |
| 18 et 19 mars | S12, S13 | 12 | Tests et incident de R2 ; reconstruction chronométrée ; point d'étape J3 |
| 26 mars | S14 | 12 | Dossier gelé, annexe II.E définitive |

**Charge** : environ 60 h, dont 23 h pour les phases 0 à 5. Les séances S4 à S6 en offrent 12 : il faut environ 11 h hors séance avant le 17 novembre. Si ce n'est pas possible, la chaîne R1 se reconstruit en S7 et le BTS blanc se fait sur l'ancienne chaîne, restaurée.

## 7. Risques et parades

| Risque | Effet | Parade |
| --- | --- | --- |
| Reconstruction refusée par le formateur | Plan sans objet | Validation en S4, avant toute destruction ; sinon, les phases 6 à 12 s'appliquent à l'existant |
| Labo inaccessible pendant le stage | Sept semaines sans travail sur le labo | Le vérifier en phase 0 ; terminer les phases 0 à 5 avant le 17 novembre |
| Chaîne R1 neuve pas prête le 13 novembre | Rien à montrer au point J1 ni au blanc | Restaurer les anciennes VM WEB, HAProxy et BDD : même adressage, elles reprennent leur place |
| Ressources refusées | Wazuh (8 Go) impossible | rsyslog central et Suricata à la place de Wazuh ; SIEM et COLLAB éteintes hors usage |
| Démarrage à froid de Galera le jour J | Site en erreur pendant l'épreuve | Procédure 06 §5, script de vérification, démarrage du labo 30 min avant |
| Licence d'évaluation expirée avant l'épreuve | ADPSQS ou le poste inutilisable | Dates notées en phase 0, prolongation (`slmgr /rearm`) ou licence de l'école |
| Application incompatible avec la version de PHP | Charge de travail de R1 en panne | Tester le code avant de trancher D1 |
| Secret publié dans Git | Règle du dépôt enfreinte, risque réel | Vault hors dépôt, `.gitignore`, masquage par `collecte-preuves.sh`, relecture de `git diff` |
| Erreur de règle sur pfSense | Labo inaccessible | Console Proxmox ; export de la configuration à chaque séance |

## 8. Le jour de l'épreuve

- Démarrer le labo au moins 30 minutes avant, dans l'ordre du [README des annexes](../quentin-scarpa/annexes/README.md#démarrer-et-arrêter-le-laboratoire) ; amorcer Galera sur le dernier nœud arrêté.
- Lancer le script de vérification (phase 12) et corriger avant d'entrer.
- Avoir hors du dépôt : identifiants, phrase secrète de la clé SSH, mot de passe du Vault ; accès à la console Proxmox.
- Garder des captures et une courte vidéo de chaque réalisation en secours, si le réseau de l'école tombe.

## 9. Ce que la reconstruction apporte au dossier

- **Déployer (12) et automatiser (14)** : la reconstruction par Ansible et PowerShell est elle-même la preuve.
- **Lignes 16 et 25** : gestion des configurations et procédures automatisées, démontrées par un `git log` et une reconstruction chronométrée.
- **Rejouabilité** : la phase 2 de l'épreuve demande de réaliser une évolution en 1 h ; des playbooks rejouables rendent ce temps réaliste.
- **Documentation fidèle** : les valeurs « à vérifier » du DAT v1.4 sont relevées et le DAT v2.0 décrit ce qui tourne vraiment.

## Sources

- [Référentiel du BTS Services informatiques aux organisations](https://siec.education.fr/candidats/docutheque/download/referentiels-des-brevets-de-technicien-superieur-bts/BTS_ServicesInformatiquesOrganisations-pdf), SIEC : annexe II.E et définition de l'épreuve, consulté le 29 octobre 2026.
- Documents du parcours U6 dans `nom-prenom/` : checklist de l'annexe II.E (outil de la commission, annexe VII-7), grille nationale d'évaluation, lettres de mission N3 et N4.
- Intégrations Zabbix : [GLPI](https://www.zabbix.com/integrations/glpi) et [pfSense](https://www.zabbix.com/integrations/pfsense), consultées le 29 octobre 2026.
