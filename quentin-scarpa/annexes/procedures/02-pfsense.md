# 02 · pfSense : routage, filtrage et publication du site

| | |
| --- | --- |
| **Machine(s)** | `pfSense` (VM 611) |
| **Zone et adresse** | WAN `10.2.0.198` ; passerelle `.254` dans chaque VLAN (à vérifier) |
| **État** | Partiel : routage et NAT en place, règles à vérifier, relais DHCP et Suricata à venir |
| **Référence DAT** | §7, §13, §19 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer à l'état réel avant de les citer comme preuve dans le dossier E6.

## 1. Objectif et périmètre

pfSense est la seule porte entre les quatre zones et vers le réseau de l'école. Il route entre les VLAN, n'autorise que les flux de la matrice (refus par défaut, journalisé) et publie le site par NAT. Cette procédure ne couvre pas l'installation de pfSense.

## 2. Valeurs du laboratoire

| Interface | VLAN | Réseau | Adresse de pfSense |
| --- | --- | --- | --- |
| WAN | n/a | Réseau de l'école (masque à relever) | 10.2.0.198 |
| WEB | 164 | 10.100.164.0/24 | 10.100.164.254 (à vérifier) |
| ADM | 165 | 10.100.165.0/24 | 10.100.165.254 (à vérifier) |
| BDD | 166 | 10.100.166.0/24 | 10.100.166.254 (à vérifier) |
| USERS | 167 | 10.100.167.0/24 | 10.100.167.254 (à vérifier) |

## 3. Prérequis

- VM pfSense créée, avec une carte WAN et une carte interne **sans étiquette VLAN** (procédure 01).
- Accès à l'interface web de pfSense depuis une machine du labo.
- La matrice des flux du DAT §7 sous les yeux.

## 4. Procédure

### 4.1 Créer les interfaces VLAN

1. **Interfaces**, **Assignments**, onglet **VLANs**, **Add**.
2. **Parent Interface** : la carte interne. **VLAN Tag** : `164`. **Description** : `WEB`. Enregistrer.
3. Répéter pour `165` (ADM), `166` (BDD) et `167` (USERS).
4. Onglet **Interface Assignments** : ajouter chaque VLAN depuis la liste **Available network ports**.
5. Ouvrir chaque interface et régler :
   - **Enable interface** coché ;
   - **Description** : `WEB`, `ADM`, `BDD` ou `USERS` ;
   - **IPv4 Configuration Type** : `Static IPv4` ;
   - **IPv4 Address** : l'adresse `.254` du tableau du §2, masque `/24`.
6. **Save**, puis **Apply Changes**.

### 4.2 Régler l'interface WAN

L'adresse WAN `10.2.0.198` est une adresse privée du réseau de l'école. Par défaut, pfSense **bloque les réseaux privés** sur le WAN : les postes de l'école n'atteindraient pas le site.

1. **Interfaces**, **WAN**.
2. Décocher **Block private networks and loopback addresses**.
3. Laisser **Block bogon networks** coché.
4. **Save**, **Apply Changes**.

### 4.3 Créer les alias

Une règle écrite avec des alias reste juste quand une adresse change. **Firewall**, **Aliases**, **Add**.

| Alias | Type | Contenu |
| --- | --- | --- |
| `HAPROXY` | Host | 10.100.164.2 |
| `WEB_SERVERS` | Host | 10.100.164.1, 10.100.164.3 |
| `DB_NODES` | Host | 10.100.166.3, 10.100.166.4, 10.100.166.5 |
| `ADPSQS` | Host | 10.100.165.1 |
| `ADMIN_PC` | Host | Adresse du poste d'administration (à relever) |
| `PORTS_SQL_CHECK` | Port | 3306, 9200 |
| `RFC1918` | Network | 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 |

### 4.4 Écrire les règles de filtrage

Les règles se lisent **sur l'interface où le trafic entre**. La première règle qui correspond s'applique ; sans correspondance, le trafic est refusé.

**Firewall**, **Rules**, onglet de l'interface, **Add**. Exemples tirés de la matrice (DAT §7) :

| Interface | Action | Protocole | Source | Destination | Port | Flux |
| --- | --- | --- | --- | --- | --- | --- |
| WEB | Pass | TCP | `HAPROXY` | `DB_NODES` | `PORTS_SQL_CHECK` | F4, F5 |
| WEB, ADM, BDD | Pass | TCP/UDP | Réseau de l'interface | `ADPSQS` | 53 | F7 |
| WEB, BDD | Pass | TCP | Réseau de l'interface | `RFC1918` en **inversant** la destination (*Invert match*) | 80, 443 | F10 |
| Toutes | Block, **Log** | Any | Any | Any | Any | F28 |

La règle F10 évite d'ouvrir HTTP et HTTPS vers les autres zones : l'inversion de `RFC1918` limite la destination à Internet.

Activer aussi la journalisation du refus par défaut : **Status**, **System Logs**, **Settings**, cocher **Log packets matched from the default block rules**.

### 4.5 Publier le site et l'administration (NAT)

**Firewall**, **NAT**, onglet **Port Forward**, **Add**.

Publication du site :

| Champ | Valeur |
| --- | --- |
| Interface | WAN |
| Protocol | TCP |
| Destination | WAN address |
| Destination port range | 8081 |
| Redirect target IP | `10.100.164.2` (HAProxy) |
| Redirect target port | 80 |
| Filter rule association | Add associated filter rule |

Redirections SSH d'administration (DAT §7, flux F11). Pour chacune : TCP, destination `WAN address`, cible sur le port 22.

| Port WAN | Cible | Machine |
| --- | --- | --- |
| 2222 | 10.100.165.1 | ADPSQS |
| 2223 | 10.100.164.1 | WEB1 |
| 2224 | 10.100.165.10 | OPS (VM 607), adresse proposée |
| 2225 | 10.100.166.3 | DB1 |
| 2226 | 10.100.166.4 | DB2 |
| 2227 | 10.100.166.5 | DB3 |
| 2228 | 10.100.164.3 | WEB2 |
| 2253 | 10.100.164.2 | HAProxy |

Limiter la source de ces redirections à l'alias `ADMIN_PC` réduit la surface exposée au réseau de l'école.

Vérifier enfin **Firewall**, **NAT**, **Outbound** : le mode `Automatic` suffit pour que les serveurs sortent vers Internet (flux F10).

### 4.6 Exporter la configuration

**Diagnostics**, **Backup & Restore**, **Download configuration as XML**. Cocher **Encrypt this configuration file** et choisir un mot de passe.

Le fichier contient des empreintes de mots de passe : il ne va **jamais** dans ce dépôt (le `.gitignore` bloque `config-*.xml`). Le garder chiffré, hors du dépôt public.

## 5. Vérification

| Test | Commande ou action | Résultat attendu |
| --- | --- | --- |
| Passerelle joignable | `ping 10.100.164.254` depuis WEB1 | Réponse |
| Site publié | `curl -I http://10.2.0.198:8081` depuis le réseau de l'école | `HTTP/1.1 200` ou `302`, servi par WordPress |
| Flux autorisé | HAProxy vers DB1, port 3306 : `nc -zv 10.100.166.3 3306` | Connexion réussie |
| Flux refusé | WEB1 vers l'annuaire en SMB : `nc -zv 10.100.165.1 445` | Échec, ligne de blocage dans le journal (test T03) |
| Journal des refus | **Status**, **System Logs**, **Firewall** | Ligne de blocage avec règle, source, destination, port |
| États | **Diagnostics**, **States** | Connexions NAT visibles pendant un accès au site |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| Site injoignable depuis l'école | **Block private networks** actif sur le WAN | §4.2 |
| Site injoignable, WAN réglé | Redirection absente ou règle associée manquante | Contrôler **NAT**, **Port Forward**, et la règle sur **WAN** |
| `502` ou délai dépassé | HAProxy éteint | Démarrer HAProxy (procédure 07) |
| Flux légitime bloqué | Règle placée après un blocage, ou mauvaise interface | Lire le journal, déplacer la règle, vérifier l'interface d'entrée |
| Plus d'accès à l'interface web | Règle trop stricte | Console Proxmox, option 8 (shell) ou restauration de la configuration exportée |

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/pfsense/` :

- `01-interfaces-vlan.png` : liste des interfaces avec VLAN et adresses.
- `02-regles-web.png` : règles de l'interface WEB.
- `03-nat-port-forward.png` : redirections 8081 et SSH.
- `04-journal-refus.png` : un flux refusé dans le journal du pare-feu (T03).

## 8. Suite prévue

- **Relais DHCP** (zone USERS) : **Services**, **DHCP Relay**, activer, interface `USERS`, serveur de destination `10.100.165.1`. Désactiver le serveur DHCP de pfSense sur cette interface : les deux ne cohabitent pas. Voir la procédure 04.
- **Journaux distants** : **Status**, **System Logs**, **Settings**, **Remote Logging Options**. pfSense n'envoie qu'en UDP (DAT §20).
- **Suricata** : paquet pfSense, en détection d'abord (DAT §16).
- **Suppression des redirections SSH** une fois le bastion validé (phase 3).

## 9. Points à vérifier

- [ ] Passerelles en `.254` sur chaque VLAN (menu **Interfaces**).
- [ ] Cible de la redirection 8081 : HAProxy, ou encore WEB1.
- [ ] Masque et passerelle du réseau de l'école côté WAN.
- [ ] Règles réelles comparées à la matrice F1 à F28 (le refus par défaut est marqué *à vérifier*).
- [ ] Redirections SSH : chacune vise bien le port 22.

## 10. Références

- [Alias](https://docs.netgate.com/pfsense/en/latest/firewall/aliases.html), pfSense.
- [Relais DHCP](https://docs.netgate.com/pfsense/en/latest/services/dhcp/relay.html), pfSense.
- [Journalisation distante](https://docs.netgate.com/pfsense/en/latest/monitoring/logs/remote.html), pfSense.
