# Fiche descriptive — Réalisation 1

> Gabarit provisoire : à aligner sur le **modèle officiel de la session 2027** dès qu'il est reçu.
> Les identifiants (nom, n° de candidat) figurent dans le dossier officiel, pas dans ce dépôt.

*Version 1, remise en S3 (29 octobre 2026). Les résultats observés seront complétés au fil des tests (S5 à S7).*

## 1. Identification

| Rubrique | Contenu |
|---|---|
| **N° de réalisation** | 1 |
| **Mission GSB** | **N3 — Haute disponibilité de l'application de suivi des visites.** Socle : lot 1 (serveurs web et répartition de charge), lot 2 (base de données répliquée), lot 4 (plan de continuité). Extension : lot 3 (redondance du répartiteur) |
| **Intitulé de la réalisation** | Mise en place d'une chaîne web haute disponibilité (HAProxy, deux serveurs Apache, grappe MariaDB Galera) pour que l'application de suivi des visites de GSB reste accessible quand un serveur tombe |
| **Organisation cliente** | GSB (Galaxy Swiss Bourdin), siège administratif Europe à Paris, service Réseau et Système. *Besoin :* l'application de suivi des visites et des frais est l'outil quotidien des 480 visiteurs médicaux ; une panne les immobilise et retarde le remboursement de leurs frais. La DSI veut que l'application continue de fonctionner si un serveur web tombe et que la base soit répliquée pour reprendre vite, sans fuite ni perte de données |
| **Période de réalisation** | Du 9 octobre 2026 (choix de la mission, S2) au 14 janvier 2027 (S8). La chaîne HAProxy, Apache et Galera, montée auparavant dans mon laboratoire, sert de point de départ |
| **Lieu de réalisation** | My Digital School, Caen : laboratoire virtualisé sur le cluster Proxmox VE de l'école |
| **Modalité** | Seul(e) ☒ · En équipe ☐ — *ma part personnelle :* totalité (conception, installation, tests, documentation) |
| **Compétences travaillées** | Concevoir ☒ · Installer, tester, déployer ☒ · Exploiter, dépanner, superviser ☒ |

> ⚠️ Ne coche une famille que si une **preuve** la soutient (voir §5).

## 2. Conditions de réalisation

**Ressources fournies** (laboratoire existant, plan d'adressage, schéma, images…) : cluster Proxmox VE de l'école et son réseau virtuel ; accès au réseau de l'école (adresse WAN `10.2.0.198` attribuée à mon pfSense) ; image Debian de base ; lettre de mission N3, conventions et fiche GSB ; application de référence de suivi des visites, fournie par le formateur comme charge de travail (à recevoir : WordPress tient ce rôle en attendant). Mon laboratoire existant (pfSense et quatre VLAN, annuaire, chaîne web) est décrit dans le [DAT d'environnement](annexes/dat/dat-environnement.md) ; plan d'adressage et schéma y figurent, avec la [table de correspondance GSB](annexes/dat/correspondance-gsb.md).

**Résultats attendus, testables**

| N° | Je dois pouvoir… | Résultat observé | Preuve (annexe) |
|---|---|---|---|
| 1 | Ouvrir l'application en **HTTPS** à travers le répartiteur | Site publié en HTTP seulement (`http://10.2.0.198:8081`) ; HTTPS prévu en S5 | Plan de tests, R1-T01 |
| 2 | Arrêter un serveur web : l'application **reste accessible** et je le prouve | Mécanisme en place (HAProxy retire un Apache en panne) ; mesure à faire | R1-T03 à R1-T05, `annexes/captures/bascules/` |
| 3 | Montrer la **répartition** des requêtes entre les deux serveurs | Tour de rôle configuré ; preuve à produire | R1-T02 |
| 4 | Arrêter la base principale, **basculer** sur la réplique et **retrouver les données** | Bascule de DB1 vers DB2 observée, site resté en ligne (DAT v1.4, §2) ; données et délai à mesurer | R1-T06, R1-T07 |
| 5 | Annoncer le **délai de reprise mesuré** et le comparer à l'objectif | Objectifs fixés (DAT R1 §3) ; mesures à faire avec `annexes/scripts/mesure-bascule.sh` | Tableau des pannes testées |
| 6 | Me connecter à un serveur **uniquement par clé**, depuis le réseau d'administration, et **montrer le journal** | Accès par clé en place ; restriction au poste d'administration à faire (S4) | R1-T11, procédure 03 |
| 7 | *(extension)* Arrêter le répartiteur principal : l'adresse virtuelle passe sur le second et le service reprend | À construire (HAProxy2 et keepalived) | R1-T13, R1-T14 |

## 3. Ressources utilisées

| Type              | Liste (avec versions) |
| ----------------- | --------------------- |
| **Documentaires** | Lettre de mission N3, conventions et fiche GSB (formateur) ; HAProxy : manuel de configuration et article « Failover and worst case management » ; MariaDB : documentation Galera (quorum, configuration, limites, redémarrage) ; WordPress : `wp-config.php` ; pfSense : alias, NAT ; Proxmox VE : sauvegarde et restauration ; RGPD, article 32 ; recommandation de la CNIL sur la journalisation |
| **Matérielles**   | Cluster Proxmox VE de l'école, sans équipement physique dédié ; 7 VM pour la chaîne (pfSense, HAProxy, WEB1, WEB2, DB1, DB2, DB3), 2 vCPU par VM Linux ; 1 VM de plus pour l'extension (HAProxy2 : 1 vCPU, 1 Go) ; poste d'administration sur le réseau de l'école ; smartphone pour les tests |
| **Logicielles**   | Proxmox VE et pfSense (versions à relever) ; Debian (version à relever) ; HAProxy (version à relever) ; Apache 2 et PHP (versions à relever) ; MariaDB 10.11 et Galera 4 ; WordPress (version à relever) ; keepalived (à installer) ; outils de test : `curl`, `ab`, `socat`, `nc` ; Git. Les versions à relever sont lues par `annexes/scripts/collecte-preuves.sh` |

## 4. Descriptif

| Rubrique                                                         | Contenu |
| ---------------------------------------------------------------- | ------- |
| **Contexte et besoin de GSB**                                    | 480 visiteurs médicaux enregistrent chaque jour leurs visites et leurs frais dans l'application. Sans elle, ils ne travaillent plus et leurs frais sont remboursés en retard. Objectifs retenus : aucune erreur visible à l'arrêt d'un serveur web, reprise en 15 s au plus après la panne de la base principale, aucune transaction validée perdue ([DAT R1](annexes/dat/dat-r1.md) §1 et §3) |
| **Cadre juridique**                                              | RGPD : données de salariés (visiteurs, frais) et de praticiens. L'article 32 exige disponibilité, résilience, capacité de rétablir l'accès aux données et tests réguliers de ces mesures : c'est l'objet de la réalisation. Chaque copie (nœud, sauvegarde) est protégée comme l'original ; la réplication de GSB vers les États-Unis doit être encadrée (Data Privacy Framework ou clauses contractuelles types). Journaux : adresses IP conservées 6 mois à 1 an (CNIL). Logiciels libres (GPL v2, licence Apache 2.0) ; code de l'application utilisé sans modification ([DAT R1](annexes/dat/dat-r1.md) §2) |
| **Solution retenue** et **alternatives écartées** (pourquoi)     | Grappe Galera de 3 nœuds plutôt qu'une réplication asynchrone : aucune transaction perdue et bascule sans intervention humaine, au prix d'une VM de plus. HAProxy plutôt que Nginx libre (pas de contrôle actif) ou un DNS à tour de rôle (ne retire pas un serveur en panne). keepalived plutôt que la haute disponibilité de Proxmox (plusieurs minutes, hors de mon périmètre). HTTPS terminé sur HAProxy avec l'autorité interne de pfSense : Let's Encrypt est impossible sans nom public ([DAT R1](annexes/dat/dat-r1.md) §4) |
| **Impact sur mon laboratoire existant**                          | HAProxy devant Galera : comptes MariaDB créés pour l'adresse de HAProxy, flux 3306 et 9200 ouverts de WEB vers BDD. Avec keepalived : NAT et `DB_HOST` vers l'adresse virtuelle `10.100.164.10`, compte MariaDB et règles pfSense ajoutés pour HAProxy2. HTTPS : nouveau port WAN, adresses WordPress en `https`. Restriction des redirections SSH au poste d'administration. Retour arrière prévu pour chaque évolution ([DAT R1](annexes/dat/dat-r1.md) §5) |
| **Mise en place** (étapes, renvoi vers les procédures en annexe) | 1. VM et VLAN ([procédure 01](annexes/procedures/01-proxmox-vm-reseau.md)). 2. Filtrage et publication ([02](annexes/procedures/02-pfsense.md)). 3. Administration par clé ([03](annexes/procedures/03-ssh-par-cle.md)). 4. Grappe Galera et contrôle de santé sur le port 9200 ([06](annexes/procedures/06-mariadb-galera.md)). 5. HAProxy pour le web et le SQL ([07](annexes/procedures/07-haproxy.md)). 6. Site sur WEB1 et WEB2 ([05](annexes/procedures/05-apache-php-wordpress.md)). 7. Bascules et retour à la normale ([08](annexes/procedures/08-bascules-et-retour-a-la-normale.md)). À venir : HTTPS (S5), HAProxy2 et keepalived (lot 3) |
| **Tests réalisés** (renvoi vers le rapport en annexe)            | [Plan de tests R1](annexes/tests/plan-de-tests-r1.md) : 15 tests, exécution de S5 à S7. À ce jour, seule la bascule de DB1 a été observée, sans mesure ; aucun résultat chiffré. Le rapport de tests suivra en S7 |
| **Exploitation** : supervision, incident, mode dégradé           | État des serveurs par la page de statistiques HAProxy (zone ADM) et le socket d'administration ; indicateurs `wsrep` de chaque nœud ; journaux HAProxy, MariaDB, SSH et Apache. Mode dégradé et maintenance sans coupure (vidage d'un serveur) dans la [procédure 08](annexes/procedures/08-bascules-et-retour-a-la-normale.md). Exercice d'incident en S7. Alertes automatiques en R2 (supervision) |
| **Amélioration proposée au-delà du besoin**                      | 1. Export logique quotidien sur DB3, restauration testée : la grappe réplique aussi une suppression, l'export la rattrape (perte limitée à 24 h). 2. Zéro erreur visible à l'arrêt d'un serveur web grâce à `option redispatch`, mesuré avant et après. 3. Un seul écrivain garanti au retour de DB1 (`on-marked-up shutdown-backup-sessions`) |
| **Productions et schémas** (renvoi vers `annexes/`)              | [DAT R1](annexes/dat/dat-r1.md) (schéma cible, choix, impact, objectifs) ; [DAT d'environnement](annexes/dat/dat-environnement.md) et [table de correspondance GSB](annexes/dat/correspondance-gsb.md) ; schémas [`annexes/schemas/01-vue-ensemble.png`](annexes/schemas/01-vue-ensemble.png) et [`annexes/schemas/02-chaine-ha.svg`](annexes/schemas/02-chaine-ha.svg) ; procédures 01 à 08 ; [plan de tests](annexes/tests/plan-de-tests-r1.md) ; scripts [`collecte-preuves.sh`](annexes/scripts/collecte-preuves.sh) et [`mesure-bascule.sh`](annexes/scripts/mesure-bascule.sh) ; `annexes/scripts/` et `annexes/captures/` après collecte |

## 5. Preuves par sous-compétence

*À mettre à jour à chaque point d'étape (S6, S9, S13). Une ligne vide est une sous-compétence à couvrir.*

| # | Sous-compétence | Preuve (fichier dans `annexes/`) | Niveau visé |
|---|---|---|---|
| 1 | Besoin et contexte juridique | `annexes/dat/dat-r1.md` §1 et §2 | Bonne maîtrise |
| 2 | Impact d'une évolution | `annexes/dat/dat-r1.md` §5 (impact et retour arrière) ; `annexes/dat/dat-laboratoire.md` §12 | Excellente maîtrise |
| 3 | Dossier de choix et spécifications | `annexes/dat/dat-r1.md` §4 (réplication ou grappe, répartiteur, HTTPS, sessions) et exigences EX1 à EX8 | Bonne maîtrise |
| 4 | Qualité et disponibilité (choix) | `annexes/dat/dat-r1.md` §3 (objectifs de reprise) ; `annexes/dat/dat-laboratoire.md` §14 (modes dégradés, sauvegarde) | Excellente maîtrise |
| 5 | Maquetter | Labo réel ; `annexes/dat/dat-r1.md` §6 (schéma cible) ; `annexes/schemas/02-chaine-ha.svg` | Bonne maîtrise |
| 6 | Préparer les tests | `annexes/tests/plan-de-tests-r1.md` | Bonne maîtrise |
| 7 | Installer et configurer | Procédures 05, 06 et 07 ; `annexes/scripts/` (après collecte) | Bonne maîtrise |
| 8 | Continuité de service | Procédure 08 ; tableau des pannes testées (à remplir) | Excellente maîtrise |
| 9 | Qualité de service | Test de charge R1-T10 et délais mesurés (à produire) | Bonne maîtrise |
| 10 | Documentation | Procédures 01 à 08 (et leur version PDF), `annexes/README.md` | Bonne maîtrise |
| 11 | Intégration et acceptation | Rapport de tests R1 (à produire en S7) | Bonne maîtrise |
| 12 | Déployer | Procédure 05 §4.6 (site copié sur WEB2) ; déploiement de HAProxy2 (lot 3, à venir) | Bonne maîtrise |
| 13 | Administrer sur site et à distance | Procédure 03 ; R1-T11 (clé, refus, journal) | Bonne maîtrise |
| 14 | Automatiser | `annexes/scripts/collecte-preuves.sh`, `annexes/scripts/mesure-bascule.sh` ; contrôle de santé Galera (`annexes/scripts/galera/`, après collecte) | Maîtrise partielle |
| 15 | Indicateurs et journaux | Indicateurs `wsrep` et `show stat`, mesures CSV (`annexes/captures/`) ; `annexes/dat/dat-laboratoire.md` §20 | Bonne maîtrise |
| 16 | Incident ou problème | Rapport d'incident de l'exercice de S7 (à produire) | Bonne maîtrise |
| 17 | Maintenir et améliorer la qualité | Mesures avant et après `option redispatch` ; export logique restauré (R1-T15) | Bonne maîtrise |

## 6. Modalités d'accès aux productions

| Rubrique | Contenu |
|---|---|
| **Dépôt des livrables** | URL : https://github.com/QuentinSCP/lab-sisr (dossier `quentin-scarpa/`) |
| **Documentation complète** | Lien : [`annexes/README.md`](annexes/README.md) (laboratoire, procédures et leur version PDF, preuves, ordre de démarrage) |
| **Comptes ou accès nécessaires** | Site : `http://10.2.0.198:8081` depuis le réseau de l'école. Administration : SSH par clé ; la clé publique du formateur est ajoutée sur demande. Identifiants WordPress et page de statistiques HAProxy : remis par un autre canal |
