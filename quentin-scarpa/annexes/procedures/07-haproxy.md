---
sous_titre: "Répartition web et bascule SQL"
version: "1.2"
date: "30/10/2026"
statut: "À valider"
diffusion: "Formateur, dossier E6"
machines: "HAProxy (VM 616)"
composants:
  - nom: "HAProxy"
    detail: "VM 616, 10.100.164.2"
    icone: split
  - nom: "Apache"
    detail: "WEB1 et WEB2"
    icone: server
  - nom: "Galera"
    detail: "DB1, secours DB2 et DB3"
    icone: database
  - nom: "Contrôle 9200"
    detail: "Synced et Primary"
    icone: activity
  - nom: "Statistiques"
    detail: "port 8404, zone ADM"
    icone: file-text
  - nom: "socat"
    detail: "socket d'administration"
    icone: terminal
historique:
  - version: "1.0"
    date: "08/10/2026"
    auteur: "Q. Scarpa"
    modifications: "Création, à partir du DAT v1.4"
  - version: "1.1"
    date: "29/10/2026"
    auteur: "Q. Scarpa"
    modifications: "Ajout des traces relevées par script"
  - version: "1.2"
    date: "30/10/2026"
    auteur: "Q. Scarpa"
    modifications: "Rangement dans les annexes, version PDF"
---

# 07 · HAProxy : répartition web et bascule SQL

| | |
| --- | --- |
| **Machine(s)** | `HAProxy` (VM 616) |
| **Zone et adresse** | WEB (VLAN 164), `10.100.164.2` (à vérifier) |
| **État** | En place (réglages réels à comparer à la configuration de référence) |
| **Référence DAT** | §9, §10, §12, §19 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer à l'état réel avant de les citer comme preuve dans le dossier E6. La configuration du §4.2 passe `haproxy -c` (HAProxy 2.8) ; la version installée sur la VM est à relever avec `haproxy -v`.

## 1. Objectif et périmètre

HAProxy est le point d'entrée unique du site :

- **Web** : il répartit les requêtes HTTP entre WEB1 et WEB2 (couche 7) et retire un Apache en panne.
- **SQL** : il envoie toutes les requêtes à DB1 et bascule sur DB2, puis DB3, si DB1 tombe (couche 4).

Il reste un point unique de défaillance : une seconde instance avec keepalived est prévue (§8).

## 2. Valeurs du laboratoire

| Élément | Valeur | Source |
| --- | --- | --- |
| Adresse | `10.100.164.2` | DAT §6 (à vérifier) |
| Entrée web | `10.100.164.2:80`, publié par pfSense sur `10.2.0.198:8081` | DAT §7 |
| Entrée SQL | `10.100.164.2:3306` | DAT §9 |
| Statistiques | Port 8404, mot de passe, zone ADM seulement | DAT §9 |
| Serveurs web | WEB1 `10.100.164.1`, WEB2 `10.100.164.3` | DAT §6 |
| Nœuds SQL | DB1 `10.100.166.3`, DB2 `.4` et DB3 `.5` en secours | DAT §6 |
| Contrôle Galera | HTTP, port 9200 de chaque nœud | DAT §9 |

## 3. Prérequis

- VM Debian dans le VLAN 164 (procédure 01).
- WEB1 et WEB2 en service (procédure 05) et nœuds Galera avec leur contrôle de santé (procédure 06, §4.4).
- Flux ouverts sur pfSense : F4 (SQL, WEB vers BDD) et F5 (contrôle, WEB vers BDD), procédure 02.

## 4. Procédure

### 4.1 Installer HAProxy

```bash
sudo apt update
sudo apt install -y haproxy socat
haproxy -v
```

`socat` sert à interroger HAProxy en ligne de commande (§5).

### 4.2 Écrire la configuration

Fichier `/etc/haproxy/haproxy.cfg` (à verser dans `annexes/scripts/haproxy/`). Les blocs `frontend`, `backend` et `listen galera` sont la configuration de référence du DAT (§9) ; `global`, `defaults` et `listen stats` complètent la configuration pour qu'elle soit exploitable seule.

```text
global
    log /dev/log local0
    maxconn 2000
    user haproxy
    group haproxy
    daemon
    stats socket /run/haproxy/admin.sock mode 660 level admin

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend site_web
    bind 10.100.164.2:80
    default_backend apache

backend apache
    balance roundrobin
    option forwardfor
    option httpchk GET /
    server web1 10.100.164.1:80 check
    server web2 10.100.164.3:80 check

listen galera
    bind 10.100.164.2:3306
    mode tcp
    option tcplog
    timeout client 1h
    timeout server 1h
    option httpchk
    http-check send meth GET uri / ver HTTP/1.1 hdr Host galera
    http-check expect status 200
    default-server check port 9200 inter 3s fall 2 rise 3 on-marked-down shutdown-sessions
    server db1 10.100.166.3:3306
    server db2 10.100.166.4:3306 backup
    server db3 10.100.166.5:3306 backup

listen stats
    bind 10.100.164.2:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth <UTILISATEUR>:<MOT_DE_PASSE>
    http-request deny unless { src 10.100.165.0/24 }
```

**Ce que chaque réglage change**

| Réglage | Effet |
| --- | --- |
| `balance roundrobin` | Les requêtes web alternent entre WEB1 et WEB2 |
| `option forwardfor` | HAProxy ajoute l'adresse du client dans `X-Forwarded-For` |
| `option httpchk GET /` | Un Apache en panne est retiré, puis réintégré dès qu'il répond |
| `mode tcp` (bloc `galera`) | Le SQL est relayé sans être lu (couche 4) |
| `backup` sur DB2 et DB3 | Un seul nœud reçoit les écritures : pas de conflit entre nœuds Galera |
| `check port 9200` | L'état d'un nœud se lit sur le contrôle HTTP, pas sur le port 3306 |
| `inter 3s fall 2 rise 3` | Nœud retiré après 2 contrôles ratés (environ 6 s), réintégré après 3 réussis (environ 9 s) |
| `on-marked-down shutdown-sessions` | Les connexions vers un nœud en panne sont fermées : PHP se reconnecte aussitôt au suivant |
| `http-request deny unless { src ... }` | La page de statistiques n'est lisible que depuis la zone ADM |

**Ordre de secours** : DB2 prend le relais si DB1 tombe, DB3 seulement si DB2 tombe aussi. Quand DB1 revient, HAProxy lui rend la main.

### 4.3 Valider puis appliquer

Toujours valider **avant** de recharger : une erreur de syntaxe coupe le site.

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
sudo systemctl status haproxy
```

`haproxy -c` doit afficher `Configuration file is valid`.

### 4.4 Ouvrir la page de statistiques depuis la zone ADM

La page n'est joignable que depuis `10.100.165.0/24`. Cela suppose une règle pfSense de ADM vers `10.100.164.2`, port 8404 (procédure 02, §4.4). Sans règle, la page reste inaccessible : c'est voulu.

Depuis une machine de la zone ADM : `http://10.100.164.2:8404/stats`.

## 5. Vérification

| Test | Commande ou action | Résultat attendu |
| --- | --- | --- |
| Configuration | `sudo haproxy -c -f /etc/haproxy/haproxy.cfg` | `Configuration file is valid` |
| Écoute | `sudo ss -ltnp \| grep haproxy` | Ports 80, 3306 et 8404 sur `10.100.164.2` |
| Site par le NAT | `curl -I http://10.2.0.198:8081` depuis l'école | `200` ou `302` |
| État des serveurs | `echo "show stat" \| sudo socat stdio /run/haproxy/admin.sock \| cut -d, -f1,2,18` | `web1`, `web2`, `db1`, `db2`, `db3` avec `UP` (DB2 et DB3 : `UP` en secours) |
| Page de statistiques | Navigateur de la zone ADM | Serveurs au vert |
| Panne d'un Apache | `sudo systemctl stop apache2` sur WEB1 | WEB1 `DOWN` après environ 6 s, site toujours en ligne (tests T08 et T10) |
| Panne de DB1 | `sudo systemctl stop mariadb` sur DB1 | `db1` `DOWN`, `db2` prend le relais, site en ligne (test S2) |
| Retour de DB1 | `sudo systemctl start mariadb` sur DB1 | `db1` `UP` après resynchronisation et 3 contrôles réussis |

Après chaque test de panne, redémarrer le service arrêté et vérifier que le serveur repasse `UP`.

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| `503 Service Unavailable` sur le site | Les deux Apache sont déclarés en panne | Lire `show stat` ; tester `curl -I http://10.100.164.1` depuis HAProxy |
| Un Apache reste `DOWN` alors qu'il tourne | `GET /` renvoie une erreur, ou flux F2 fermé | `curl -I http://10.100.164.1/` depuis HAProxy |
| Tous les nœuds Galera `DOWN` | Contrôle sur le port 9200 injoignable, ou nœuds non Primary | `curl -i http://10.100.166.3:9200/` depuis HAProxy ; règle pfSense F5 ; procédure 06 |
| `Access denied for user ... @'10.100.164.2'` | Compte MariaDB créé pour l'adresse du serveur web, pas celle de HAProxy | Procédure 06, §4.6 |
| `haproxy -c` signale une erreur | Faute de frappe dans la configuration | Corriger la ligne indiquée avant tout `reload` |
| Page de statistiques refusée | Accès hors zone ADM, ou règle pfSense absente | §4.4 |
| Adresse du client illisible dans Apache | `X-Forwarded-For` non lu par Apache | Procédure 05, §4.8 |

Les journaux se lisent avec `journalctl -u haproxy` (ou `/var/log/haproxy.log` si `rsyslog` est installé) : client, serveur choisi, code HTTP, durée, serveurs retirés ou réintégrés.

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/haproxy/` :

- `01-configuration-valide.png` : `haproxy -c` et la configuration.
- `02-statistiques-nominal.png` : tous les serveurs au vert.
- `03-statistiques-panne-web1.png` : WEB1 en rouge, site en ligne.
- `04-statistiques-panne-db1.png` : DB1 en rouge, DB2 actif.
- `05-journal-haproxy.png` : serveur retiré puis réintégré.
- Traces texte : `annexes/captures/haproxy/AAAA-MM-JJ-haproxy-etat.txt` (validation, état des serveurs, retraits et retours) et `annexes/scripts/haproxy/haproxy.cfg` (mot de passe des statistiques masqué), relevés par `annexes/scripts/collecte-preuves.sh`.

## 8. Suite prévue

- **Seconde instance** `HAProxy2` (`10.100.164.4`, proposée) avec **keepalived** et une adresse virtuelle `10.100.164.10` (proposée). Le protocole VRRP (numéro 112) circule entre les deux instances, dans le même VLAN (flux F23). Cible de la redirection 8081 de pfSense : l'adresse virtuelle.
- **HTTPS** : certificat d'une autorité interne, `WP_HOME` en `https`, en-tête `X-Forwarded-Proto` transmis à WordPress (DAT §12).
- **Exporter HAProxy** pour Prometheus (phase Sentinelle).

## 9. Points à vérifier

- [ ] Adresse de HAProxy (`10.100.164.2` retenue ici).
- [ ] Réglages réels de `/etc/haproxy/haproxy.cfg`, comparés au §4.2.
- [ ] Cible de la redirection 8081 sur pfSense : HAProxy, ou encore WEB1.
- [ ] Protection de la page de statistiques (mot de passe et filtrage par zone).
- [ ] Version de HAProxy (`haproxy -v`).

## 10. Références

- [Bascule et serveurs de secours](https://www.haproxy.com/blog/failover-and-worst-case-management-with-haproxy), HAProxy.
- [Adresses du site](https://developer.wordpress.org/advanced-administration/wordpress/wp-config/), WordPress.
