# 08 · Bascules, pannes et retour à la normale

| | |
| --- | --- |
| **Machine(s)** | `HAProxy` (616), `WEB1` (609), `WEB2` (615), `DB1` (612), `DB2` (613), `DB3` (614) |
| **Zone et adresse** | WEB (164) et BDD (166) ; commandes lancées depuis le poste d'administration |
| **État** | En place pour le web et la base ; délais à mesurer (plan de tests R1) |
| **Référence DAT** | §9, §10, §14 · [DAT R1](../dat/dat-r1.md) §3 et §7 |
| **Dernière vérification sur la machine** | À faire en S5 |

> Procédure d'exploitation de la réalisation 1 (mission N3, lots 2 et 4). Les sorties montrées sont **attendues**, pas relevées : les traces réelles se produisent avec `annexes/scripts/mesure-bascule.sh` et `annexes/scripts/collecte-preuves.sh`, et se rangent dans `annexes/captures/`.

## 1. Objectif et périmètre

Que faire quand un serveur web ou un nœud de la base tombe, comment arrêter un serveur pour maintenance sans erreur, comment revenir à la normale et comment mesurer l'interruption. Le démarrage à froid de Galera est dans la [procédure 06](06-mariadb-galera.md#5-démarrage-à-froid-et-reprise-après-panne) ; la bascule entre deux répartiteurs aura sa procédure avec le lot 3 (keepalived).

## 2. Valeurs du laboratoire

| Élément | Valeur | Source |
| --- | --- | --- |
| Contrôle des Apache | Toutes les 2 s ; retiré après 3 échecs (≈ 6 s), réintégré après 2 succès (≈ 4 s) | Valeurs par défaut de `check`, procédure 07 |
| Contrôle des nœuds Galera | Toutes les 3 s sur le port 9200 ; retiré après 2 échecs (≈ 6 s), réintégré après 3 succès (≈ 9 s) | Procédure 07 §4.2 |
| Ordre de secours SQL | DB1, puis DB2, puis DB3 | Procédure 07 §4.2 |
| Socket d'administration | `/run/haproxy/admin.sock`, niveau `admin` | Procédure 07 §4.2 |
| Objectifs de reprise | Web : aucune erreur (arrêt du service), 10 s (VM coupée) ; base : 15 s ; aucune transaction validée perdue | DAT R1 §3 |
| Mesure | Une requête toutes les 0,5 s | `annexes/scripts/mesure-bascule.sh` |

Pour alléger les commandes, définir sur le poste d'administration :

```bash
hap() { ssh haproxy "echo '$*' | sudo socat stdio /run/haproxy/admin.sock"; }
```

`hap "show stat"` interroge alors HAProxy à distance.

## 3. Prérequis

- Procédures 05, 06 et 07 terminées, état nominal relevé (§4.1).
- Poste d'administration avec les alias SSH de la procédure 03 et `curl`.
- Deux terminaux : un pour la mesure, un pour l'action.
- Pour toute panne de la base : un export logique de moins de 24 h (procédure 06 §4.7).

## 4. Procédure

### 4.1 Relever l'état nominal

```bash
hap "show stat" | cut -d, -f1,2,18
for n in db1 db2 db3; do
    ssh "$n" "sudo mariadb -N -e \"SHOW STATUS WHERE Variable_name IN ('wsrep_cluster_size','wsrep_local_state_comment')\""
done
curl -sI http://10.2.0.198:8081/ | head -n 1
```

Sortie attendue de `show stat` (extrait) :

```text
# pxname,svname,status
apache,web1,UP
apache,web2,UP
galera,db1,UP
galera,db2,UP
galera,db3,UP
```

Les trois nœuds doivent afficher `3` et `Synced`, le site `200` ou `302`. `annexes/scripts/collecte-preuves.sh` relève le même état dans `annexes/captures/`.

### 4.2 Panne d'un serveur web

**Ce qui se passe seul** : HAProxy retire le serveur après environ 6 s ; l'autre serveur répond à toutes les requêtes.

**Ce que fait l'exploitant** :

1. Constater : `hap "show stat" | cut -d, -f1,2,18` affiche `apache,web1,DOWN`. Dans le journal :

   ```bash
   ssh haproxy "sudo journalctl -u haproxy --since -15min | grep -E 'is (UP|DOWN)'"
   ```

   Forme de la ligne attendue : `Server apache/web1 is DOWN, reason: Layer4 connection problem, info: "Connection refused", ... 1 active and 0 backup servers left.`
2. Diagnostiquer sur WEB1 : `systemctl status apache2`, `sudo tail -n 50 /var/log/apache2/error.log`, `sudo apache2ctl configtest`, `df -h`.
3. Corriger, puis `sudo systemctl start apache2`.
4. Vérifier : `apache,web1,UP` après environ 4 s, répartition rétablie (§5).
5. Consigner la panne dans le tableau des pannes du [plan de tests](../tests/plan-de-tests-r1.md).

### 4.3 Maintenance d'un serveur web, sans erreur

On vide le serveur avant de l'arrêter : il ne reçoit plus de nouvelles connexions.

```bash
hap "set server apache/web1 state drain"
hap "show stat" | cut -d, -f1,2,5     # attendre que scur (sessions en cours) vaille 0
hap "set server apache/web1 state maint"
# ... intervention sur WEB1 ...
hap "set server apache/web1 state ready"
```

Un état posé par le socket est perdu au rechargement de HAProxy : vérifier qu'aucun serveur ne reste en `MAINT` (§4.7).

### 4.4 Panne de la base principale (DB1)

**Ce qui se passe seul** : HAProxy marque DB1 en panne après environ 6 s, ferme ses connexions (`on-marked-down shutdown-sessions`) et envoie les nouvelles à DB2. La grappe passe à 2 nœuds et reste `Primary`.

**Ce que fait l'exploitant** :

1. Constater : `galera,db1,DOWN` et `galera,db2,UP` ; sur DB2, `wsrep_cluster_size` vaut `2` et `wsrep_cluster_status` vaut `Primary`.
2. Diagnostiquer DB1 : `sudo journalctl -u mariadb -n 100`, `df -h /var/lib/mysql`, `curl -i http://127.0.0.1:9200/`.
3. Corriger, puis `sudo systemctl start mariadb`. Suivre le retour avec `sudo journalctl -u mariadb -f` : le nœud rattrape les transactions manquées (IST) ou recopie la base (SST), puis annonce `Synchronized with group, ready for connections`.
4. Attendre `Synced` : HAProxy réintègre DB1 après 3 contrôles réussis (≈ 9 s) et lui rend les nouvelles connexions.
5. Vérifier qu'il n'y a qu'un écrivain : les connexions ouvertes pendant la panne restent sur DB2 tant qu'elles vivent. Avec `on-marked-up shutdown-backup-sessions` (proposé au DAT R1 §5), HAProxy les ferme au retour de DB1. Sans ce réglage, les surveiller sur DB2 : `sudo mariadb -e "SHOW PROCESSLIST"`.
6. Consigner la panne.

### 4.5 Maintenance de DB1, bascule manuelle

```bash
hap "set server galera/db1 state maint"
hap "shutdown sessions server galera/db1"   # DB2 reçoit tout le SQL
ssh db1 sudo systemctl stop mariadb
# ... intervention sur DB1 ...
ssh db1 sudo systemctl start mariadb        # attendre Synced
hap "set server galera/db1 state ready"
```

### 4.6 Perte du quorum et arrêt complet

- Deux nœuds coupés brutalement : le dernier passe en `non-Primary` et refuse les requêtes ; le site est en erreur. Reprise : [procédure 06 §5.4](06-mariadb-galera.md#54-deux-nœuds-perdus-le-dernier-refuse-les-requêtes).
- Arrêt complet : démarrage à froid, [procédure 06 §5](06-mariadb-galera.md#5-démarrage-à-froid-et-reprise-après-panne), dans l'ordre du [README des annexes](../README.md#démarrer-et-arrêter-le-laboratoire).

### 4.7 Mesurer une interruption

Terminal 1, sur le poste d'administration :

```bash
annexes/scripts/mesure-bascule.sh http://10.2.0.198:8081/ 60 panne-web1
```

Terminal 2, une dizaine de secondes après le début : provoquer la panne (`ssh web1 sudo systemctl stop apache2`), puis la réparer avant la fin de la mesure.

Le script affiche chaque requête (heure, code HTTP, serveur, durée), puis un résumé de la forme :

```text
requêtes : 120 · réussies : … · en échec : … · plus longue interruption : … s
```

Il écrit `annexes/captures/bascules/AAAA-MM-JJ-HHMMSS-panne-web1.csv` et le résumé `-resume.txt`. Précision : 0,5 s, le pas de mesure. Recopier le résultat dans le tableau des pannes.

### 4.8 Retour à la normale

- [ ] Tous les serveurs `UP` dans `show stat`, aucun en `MAINT` ou `DRAIN`.
- [ ] `wsrep_cluster_size` vaut `3` sur les trois nœuds, tous `Synced`.
- [ ] Répartition rétablie entre WEB1 et WEB2.
- [ ] Site en `200` ou `302` par le NAT.
- [ ] Panne consignée : date, action, observation, délai mesuré.

## 5. Vérification

| Test | Commande ou action | Résultat attendu |
| --- | --- | --- |
| État des serveurs | `hap "show stat" \| cut -d, -f1,2,18` | Tous `UP` |
| Répartition | `for i in 1 2 3 4; do curl -s -D - -o /dev/null http://10.2.0.198:8081/ \| grep -i x-served-by; done` | `web1` et `web2` en alternance |
| Requêtes redistribuées | `hap "show stat" \| cut -d, -f1,2,17` après l'arrêt d'un Apache | Compteur `wredis` en hausse si `option redispatch` est actif |
| Grappe | `wsrep_cluster_size` sur un nœud | `3` |
| Délai mesuré | `annexes/scripts/mesure-bascule.sh` pendant la panne | Interruption inférieure à l'objectif du DAT R1 §3 |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| Des `503` pendant environ 6 s à l'arrêt d'un Apache | HAProxy envoie encore des requêtes au serveur pas encore retiré | `option redispatch` et `retries 3` dans `defaults` (DAT R1 §5), puis mesurer à nouveau |
| Site en erreur bien au-delà de 15 s après la panne de DB1 | Contrôle 9200 absent : HAProxy ne voit pas l'état réel des nœuds | `curl -i http://10.100.166.4:9200/` depuis HAProxy ; procédure 06 §4.4 |
| DB1 ne repasse pas `UP` | Le nœud est encore `Joining` ou `Donor` (le contrôle répond `503`) | Attendre `Synced` ; `systemctl status galera-check.socket` |
| Un serveur reste hors service après une intervention | État `MAINT` posé par le socket | `hap "set server <proxy>/<serveur> state ready"` |
| Écritures en échec au retour de DB1 | Deux nœuds reçoivent des écritures | `on-marked-up shutdown-backup-sessions` dans le bloc `galera` |

## 7. Preuves à conserver pour le dossier E6

- `annexes/captures/bascules/*.csv` et `*-resume.txt` : une mesure par panne testée.
- `annexes/captures/haproxy/` : page de statistiques pendant la panne (WEB1 ou DB1 en rouge), ouverte depuis la zone ADM (navigateur d'ADPSQS) ; ou sortie de `show stat`.
- `annexes/captures/galera/` : `wsrep_cluster_size` à 2 pendant la panne, puis à 3.
- Extraits commentés de `journalctl -u haproxy` et `journalctl -u mariadb` montrant le retrait puis le retour.

## 8. Points à vérifier

- [ ] Contrôle de santé du port 9200 réellement en place sur les trois nœuds.
- [ ] `socat` installé sur HAProxy (procédure 07 §4.1).
- [ ] `option redispatch` et `on-marked-up shutdown-backup-sessions` ajoutés, avec une mesure avant et après.

## 9. Références

- [Manuel de configuration](https://docs.haproxy.org/2.8/configuration.html) (`option redispatch`, `on-marked-up`, `on-marked-down`) et [API d'exécution](https://docs.haproxy.org/2.8/management.html) (`set server`, `shutdown sessions`), HAProxy.
- [Galera : quorum, surveillance et reprise](https://mariadb.com/docs/galera-cluster/high-availability/understanding-quorum-monitoring-and-recovery), MariaDB.
