---
sous_titre: "Créer les machines, les placer dans leur VLAN et les sauvegarder"
version: "1.1"
date: "30/10/2026"
statut: "À valider"
diffusion: "Formateur, dossier E6"
machines: "Cluster Proxmox VE de l'école"
composants:
  - nom: "Proxmox VE"
    detail: "cluster de l'école"
    icone: server
  - nom: "Image Debian"
    detail: "gabarit des VM Linux"
    icone: layers
  - nom: "Pont VLAN"
    detail: "VLAN 164 à 167"
    icone: network
  - nom: "vzdump"
    detail: "sauvegarde des VM"
    icone: archive
  - nom: "qmrestore"
    detail: "restauration testée (T13)"
    icone: refresh-cw
  - nom: "Console Proxmox"
    detail: "accès de secours"
    icone: terminal
historique:
  - version: "1.0"
    date: "08/10/2026"
    auteur: "Q. Scarpa"
    modifications: "Création, à partir du DAT v1.4"
  - version: "1.1"
    date: "30/10/2026"
    auteur: "Q. Scarpa"
    modifications: "Rangement dans les annexes, version PDF"
---

# 01 · Proxmox VE : VM, réseau virtuel et sauvegardes

| | |
| --- | --- |
| **Machine(s)** | Cluster Proxmox VE de l'école (cluster à confirmer) |
| **Zone et adresse** | Toutes les zones : une VM par rôle, un VLAN par zone |
| **État** | Partiel : VM et VLAN en place, planning de sauvegarde à définir |
| **Référence DAT** | §5, §6, §7, §14 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer à l'état réel avant de les citer comme preuve dans le dossier E6.

## 1. Objectif et périmètre

Créer les VM du laboratoire depuis une image Debian de base, les placer dans le bon VLAN, puis les sauvegarder. Cette procédure ne couvre pas l'installation de Proxmox lui-même : l'hébergement est imposé par l'école.

## 2. Valeurs du laboratoire

| Élément | Valeur | Source |
| --- | --- | --- |
| Hyperviseur | Proxmox VE du cluster de l'école | DAT §6 |
| Image de base | Debian, clonée pour chaque VM Linux | DAT §6 |
| Nommage réel | Préfixe `SIO2527`, par exemple `SIO2527-MariaDB-ADM-Quentin` | DAT §6 |
| Réseau virtuel | Pont avec étiquettes VLAN, ou zone SDN | À vérifier |
| Sauvegarde | Outil intégré `vzdump` | DAT §14 |

**Machines en place**

| Machine | ID | VLAN | Adresse IP | Système |
| --- | --- | --- | --- | --- |
| pfSense | 611 | WAN + 164 à 167 | 10.2.0.198 (WAN) | pfSense |
| ADPSQS | 606 | 165 (ADM) | 10.100.165.1 | Windows Server 2022 |
| HAProxy | 616 | 164 (WEB) | 10.100.164.2 (à vérifier) | Debian |
| WEB1 | 609 | 164 (WEB) | 10.100.164.1 | Debian |
| WEB2 | 615 | 164 (WEB) | 10.100.164.3 (à vérifier) | Debian |
| DB1 | 612 | 166 (BDD) | 10.100.166.3 | Debian |
| DB2 | 613 | 166 (BDD) | 10.100.166.4 | Debian |
| DB3 | 614 | 166 (BDD) | 10.100.166.5 | Debian |

Les VM 607 (future OPS) et 621 (rôle à préciser) existent déjà et sont éteintes (DAT §6 et §18).

## 3. Prérequis

- Un compte Proxmox autorisé à cloner des VM et à les configurer.
- L'image Debian de base disponible dans le cluster.
- Le plan d'adressage du DAT §7 (une adresse fixe de `.1` à `.99` par VM, passerelle pfSense en `.254`).

## 4. Procédure

### 4.1 Créer une VM Linux depuis l'image de base

1. Dans l'interface Proxmox : clic droit sur l'image de base, **Clone**, mode **Full Clone**, choisir l'ID de la VM (tableau du §2) et son nom.

   En ligne de commande sur le nœud :

   ```bash
   qm clone <ID_IMAGE> <ID_NOUVELLE_VM> --name <NOM> --full
   ```

2. Régler la carte réseau : **Hardware**, **Network Device**, champ **VLAN Tag** à la valeur de la zone (164, 165 ou 166).

   ```bash
   qm set <ID_NOUVELLE_VM> --net0 virtio,bridge=<PONT>,tag=<VLAN>
   ```

   `<PONT>` est le nom du pont réseau de l'école (à relever, voir §4.2).

3. Démarrer la VM et ouvrir la **Console**.

4. Un clone partage l'identité de l'image : la changer, sinon deux VM annoncent le même identifiant machine et les mêmes clés SSH.

   ```bash
   hostnamectl set-hostname <nom-court>

   rm -f /etc/machine-id
   systemd-machine-id-setup
   ln -sf /etc/machine-id /var/lib/dbus/machine-id

   rm -f /etc/ssh/ssh_host_*
   dpkg-reconfigure openssh-server
   ```

5. Fixer l'adresse IP dans `/etc/network/interfaces` (exemple pour DB1) :

   ```text
   auto <INTERFACE>
   iface <INTERFACE> inet static
       address 10.100.166.3/24
       gateway 10.100.166.254
   ```

   `<INTERFACE>` se lit avec `ip -br a`. Pointer ensuite le DNS vers ADPSQS (procédure 04).

6. Redémarrer, puis vérifier :

   ```bash
   ip -br a
   ip route
   ping -c 2 10.100.166.254
   ```

### 4.2 Réseau virtuel : un VLAN par zone

Le principe retenu dans le DAT (§7) : sans switch physique, les VLAN sont portés par le réseau virtuel de Proxmox.

- Un **pont compatible VLAN** (*VLAN aware*) relie toutes les VM.
- Chaque carte de VM Linux ou Windows porte une **étiquette** : 164 (WEB), 165 (ADM), 166 (BDD), 167 (USERS).
- La carte interne de **pfSense n'a pas d'étiquette** : elle reçoit tous les VLAN et les sépare elle-même.
- Une VM ne voit jamais l'étiquette VLAN : elle n'existe qu'entre le pont et pfSense (DAT §19).

Pour relever la configuration réelle :

1. Interface Proxmox : **Nœud**, **Système**, **Réseau**, ouvrir le pont utilisé par les VM. Noter son nom et si **VLAN aware** est coché.
2. En ligne de commande : `cat /etc/network/interfaces` sur le nœud.
3. Reporter le résultat dans le DAT (§18 : « pont VLAN ou SDN »).

Exemple de pont compatible VLAN, à comparer à la configuration de l'école :

```text
auto vmbr1
iface vmbr1 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
```

Selon vos droits, cette partie est gérée par l'école : dans ce cas, la relever sans la modifier.

| VM | Étiquette VLAN de la carte |
| --- | --- |
| pfSense, carte interne | aucune (reçoit tous les VLAN) |
| HAProxy, WEB1, WEB2 | 164 |
| ADPSQS | 165 |
| DB1, DB2, DB3 | 166 |
| Postes clients (à venir) | 167 |

### 4.3 Sauvegarder avec vzdump

Interface Proxmox : **Centre de données**, **Sauvegarde**, **Ajouter**.

| Champ | Valeur proposée | Remarque |
| --- | --- | --- |
| Stockage | `<STOCKAGE_SAUVEGARDE>` | À relever, hors du disque des VM si possible |
| Sélection | VM du laboratoire (606, 609, 611 à 616) | Exclure les VM éteintes et inutiles |
| Planning | Tous les jours, `<HEURE>` | Un RPO de 24 h demande une sauvegarde quotidienne (DAT §14) |
| Mode | Snapshot | VM allumée, sans coupure |
| Compression | ZSTD | |
| Conservation | `keep-last=<N>` | À définir (DAT §14 et §18) |

Sauvegarde manuelle d'une VM, par exemple DB3 (614) :

```bash
vzdump 614 --mode snapshot --compress zstd --storage <STOCKAGE_SAUVEGARDE>
```

Restauration vers un nouvel ID, sans toucher à la VM d'origine :

```bash
qmrestore <FICHIER_SAUVEGARDE> <ID_LIBRE> --unique
```

L'option `--unique` génère de nouvelles adresses MAC et évite un conflit avec la VM d'origine. Une sauvegarde qui n'a jamais été restaurée n'est pas une preuve : c'est le test **T13** du plan de tests.

### 4.4 Ordre de démarrage

Les VM sont éteintes entre les séances. Respecter l'ordre du [README des annexes](../README.md#démarrer-et-arrêter-le-laboratoire) : pfSense, ADPSQS, Galera (un nœud amorcé, puis les deux autres), HAProxy, WEB1 et WEB2.

## 5. Vérification

| Test | Commande ou action | Résultat attendu |
| --- | --- | --- |
| Adresse et route | `ip -br a` et `ip route` sur la VM | Adresse de la zone, passerelle en `.254` |
| Joindre pfSense | `ping 10.100.164.254` depuis WEB1 | Réponse |
| Isolation des zones | `ping 10.100.166.3` depuis WEB1 | Autorisé ou refusé selon la matrice : le trafic passe par pfSense |
| Identité unique | `cat /etc/machine-id` sur deux clones | Valeurs différentes |
| Sauvegarde | Onglet **Sauvegarde** de la VM | Dernière sauvegarde réussie, datée |
| Restauration | `qmrestore ... --unique` puis démarrage | VM fonctionnelle (test T13) |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| VM sans réseau | Mauvaise étiquette VLAN, ou pont sans VLAN | Corriger **VLAN Tag** dans **Hardware** |
| Deux VM se disputent une adresse | IP fixe copiée de l'image | Changer `address` dans `/etc/network/interfaces` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` en SSH | Clés SSH de l'hôte régénérées après clonage | Voir la procédure 03 |
| `qmrestore` refuse l'ID | ID déjà utilisé | Choisir un ID libre |

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/proxmox/` :

- `01-liste-vm.png` : liste des VM avec ID, nom et état.
- `02-vlan-tag-vm.png` : onglet **Hardware** d'une VM avec son **VLAN Tag**.
- `03-tache-sauvegarde.png` : tâche de sauvegarde planifiée.
- `04-restauration-reussie.png` : restauration testée (T13).

## 8. Points à vérifier

- [ ] Proxmox : cluster ou nœud seul, version (`pveversion`).
- [ ] Réseau virtuel : pont VLAN ou zone SDN, nom du pont.
- [ ] Rôle et ressources des VM 607 et 621.
- [ ] Planning, conservation et stockage des sauvegardes.
- [ ] Chemin des sauvegardes vers un futur serveur dédié (flux F22).

## 9. Références

- [Configuration réseau](https://pve.proxmox.com/wiki/Network_Configuration), Proxmox VE.
- [Sauvegarde et restauration](https://pve.proxmox.com/wiki/Backup_and_Restore), Proxmox VE.
