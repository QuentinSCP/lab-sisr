# Plan de tests de la réalisation 1

Version 0.1 · 29 octobre 2026 · Quentin Scarpa · Mission GSB N3

Chaque test vérifie un résultat attendu de la lettre de mission N3 (colonne « N3 ») ou une exigence du [DAT R1](../dat-r1.md) (EX1 à EX8). Les colonnes « Résultat observé », « Date » et « Preuve » se remplissent **uniquement** avec ce qui a été vu sur le labo. Ces tests précisent les tests T05, T08, T10, T11 et T13 cités dans le DAT v1.4, dont le plan n'est pas encore versionné dans ce dépôt.

## 1. Environnement de test

- **Labo** : celui du [DAT d'environnement](../dat-environnement.md). Charge de travail : WordPress, puis l'application de référence de GSB.
- **Poste d'administration** : réseau de l'école, alias SSH de la procédure 03, `curl`, `ab` (paquet `apache2-utils`).
- **Outils** : `scripts/mesure-bascule.sh` (interruption), `scripts/collecte-preuves.sh` (état), `socat` sur HAProxy, `nc`.
- **Avant tout test sur la base** : export logique de moins de 24 h (procédure 06 §4.7).
- **Jeu d'essai** : une base `recette`, sans donnée personnelle, créée une fois sur DB1 (elle se réplique) :

```sql
CREATE DATABASE IF NOT EXISTS recette;
CREATE TABLE IF NOT EXISTS recette.t (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quand DATETIME DEFAULT CURRENT_TIMESTAMP,
    note VARCHAR(60)
) ENGINE=InnoDB;
```

## 2. Tests

Statut : À faire · Réussi · Échoué · Corrigé (échoué puis réussi après correction, cause notée).

| N° | N3 | Objectif | Action | Résultat attendu | Résultat observé | Date | Preuve | Statut |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R1-T01 | 1 | HTTPS à travers le répartiteur (EX1) | `curl -sv --cacert ac-interne.crt https://10.2.0.198:8444/ -o /dev/null` ; navigateur | TLS établi, émetteur : autorité interne, code `200` ; `http://…:8081` redirige vers HTTPS | | | | À faire (après HTTPS) |
| R1-T02 | 3 | Répartition des requêtes | 10 requêtes avec `X-Served-By` (procédure 08 §5) ; ou sessions cumulées `hap "show stat" \| cut -d, -f1,2,8` avant et après | Environ 5 requêtes par serveur | | | | À faire |
| R1-T03 | 2 | Arrêt d'Apache sur WEB1 (EX2) | `mesure-bascule.sh … 60 panne-web1`, puis `ssh web1 sudo systemctl stop apache2` ; à refaire après `option redispatch` | Site toujours en ligne, WEB1 `DOWN` en ≈ 6 s ; aucune erreur avec `option redispatch` | | | | À faire |
| R1-T04 | 2 | Arrêt brutal de la VM WEB1 (EX2) | Même mesure, VM 609 arrêtée par **Stop** dans Proxmox | Interruption de 10 s au plus | | | | À faire |
| R1-T05 | 2 | Retour de WEB1 | `systemctl start apache2` ou démarrage de la VM | WEB1 `UP` en ≈ 4 s, répartition rétablie | | | | À faire |
| R1-T06 | 4, 5 | Panne de DB1 (EX3) | Sur DB1 : `INSERT INTO recette.t (note) VALUES ('avant panne')` ; mesure ; `ssh db1 sudo systemctl stop mariadb` ; sur DB2 : `INSERT … ('pendant panne')` et `wsrep_cluster_size` | Site revenu en 15 s au plus ; `db2` actif ; taille 2 ; ligne « avant panne » présente | | | | À faire |
| R1-T07 | 4 | Retour de DB1, un seul écrivain | `ssh db1 sudo systemctl start mariadb` ; `SELECT * FROM recette.t` sur DB1 ; `show stat` | IST dans le journal, DB1 `Synced`, ligne « pendant panne » présente, DB1 à nouveau actif | | | | À faire |
| R1-T08 | 4, 5 | Perte du quorum | DB2 et DB3 arrêtés par **Stop** dans Proxmox ; mesure longue (`… 1800 quorum`) ; reprise par la procédure 06 §5.4 | DB1 `non-Primary`, site en erreur (refus plutôt que divergence) ; reprise en 30 min au plus, aucune donnée perdue | | | | À faire |
| R1-T09 | 5 | Arrêt complet puis démarrage à froid (T11 du DAT) | Arrêt dans l'ordre inverse du README ; chronomètre au démarrage | Site en `200` en 30 min au plus ; `wsrep_cluster_size` à 3 | | | | À faire |
| R1-T10 | — | Charge avec deux serveurs, puis un seul (EX8) | `ab -n 1000 -c 10 http://10.2.0.198:8081/`, puis la même commande avec Apache arrêté sur WEB1 | `Failed requests: 0` dans les deux cas ; requêtes par seconde notées | | | | À faire |
| R1-T11 | 6 | Administration par clé depuis le poste d'administration (EX5) | `ssh web1 hostname` ; `ssh -o PubkeyAuthentication=no web1` ; connexion depuis un autre poste de l'école ; `ssh web1 sudo journalctl -u ssh --since today` | Clé acceptée ; `Permission denied (publickey)` ; autre poste : délai dépassé ; journal avec les adresses sources | | | | À faire (après restriction à `ADMIN_PC`) |
| R1-T12 | — | Base joignable par HAProxy seul (EX6) | Depuis WEB1 : `nc -zv -w 3 10.100.166.3 3306` ; depuis HAProxy : la même commande ; journal du pare-feu | WEB1 : échec et ligne de refus dans pfSense ; HAProxy : succès | | | | À faire |
| R1-T13 | 7 | Panne du répartiteur principal (EX4) | Mesure ; `ssh haproxy sudo systemctl stop keepalived` ; sur HAProxy2 : `ip -br a` | Adresse `10.100.164.10` sur HAProxy2, interruption de 5 s au plus, le SQL suit | | | | À faire (lot 3) |
| R1-T14 | 7 | Retour du répartiteur principal | `ssh haproxy sudo systemctl start keepalived` ; mesure | Comportement conforme au réglage choisi (reprise ou non de l'adresse), interruption mesurée | | | | À faire (lot 3) |
| R1-T15 | — | Une suppression se réplique, l'export la rattrape (EX7) | Lancer l'export sur DB3 ; supprimer la ligne « avant panne » sur DB1 ; constater qu'elle a disparu sur DB2 ; restaurer la base `recette` depuis l'export | Ligne absente sur les 3 nœuds après la suppression, présente après la restauration ; durée notée | | | | À faire |

**Restaurer seulement la base `recette` depuis l'export complet** (R1-T15), sur DB3 :

```bash
zcat /var/backups/sql/all-AAAA-MM-JJ.sql.gz \
    | awk '/^-- Current Database: /{f = /`recette`/} f' \
    | sudo mariadb
```

Le bloc de la base `recette` recrée la base et ses tables, puis réinsère les lignes : la restauration se réplique sur les trois nœuds.

## 3. Tableau des pannes testées

Une ligne par panne réellement provoquée (lot 4 de N3). Le délai vient du résumé de `mesure-bascule.sh` ; la mesure brute est citée en preuve.

| Date | Panne provoquée | Comment | Observation | Délai mesuré | Objectif (DAT R1 §3) | Écart et action | Preuve |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | Apache arrêté sur WEB1 | `systemctl stop apache2` | | | Aucune erreur | | |
| | VM WEB1 coupée | **Stop** dans Proxmox | | | 10 s | | |
| | MariaDB arrêté sur DB1 | `systemctl stop mariadb` | | | 15 s | | |
| | Perte du quorum | **Stop** de DB2 et DB3 | | | 30 min | | |
| | Arrêt complet | Ordre inverse du README | | | 30 min | | |
| | HAProxy principal arrêté | `systemctl stop keepalived` | | | 5 s | | |

## 4. Test de charge

| Configuration | Commande | Requêtes par seconde | Temps moyen par requête | Requêtes en échec |
| --- | --- | --- | --- | --- |
| WEB1 et WEB2 | `ab -n 1000 -c 10 http://10.2.0.198:8081/` | | | |
| WEB2 seul | Même commande, Apache arrêté sur WEB1 | | | |

Le cluster est partagé : garder ces valeurs modérées et lancer le test en séance.
