# 03 · SSH par clé : administration à distance

| | |
| --- | --- |
| **Machine(s)** | Toutes les VM (ADPSQS, WEB1, WEB2, HAProxy, DB1 à DB3, OPS) |
| **Zone et adresse** | Accès depuis le réseau de l'école, par `10.2.0.198` et un port par machine |
| **État** | En place |
| **Référence DAT** | §7 (redirections, flux F11), §13, §15 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer à l'état réel avant de les citer comme preuve dans le dossier E6.

## 1. Objectif et périmètre

Administrer chaque machine par SSH avec une clé, sans mot de passe. Chaque machine est joignable sur l'adresse WAN de pfSense, avec son propre port. Cette procédure sera remplacée par le bastion Guacamole en phase 3 : les redirections SSH seront alors supprimées.

## 2. Valeurs du laboratoire

| Machine | Port WAN | Cible interne (port 22) |
| --- | --- | --- |
| ADPSQS | 2222 | 10.100.165.1 |
| WEB1 | 2223 | 10.100.164.1 |
| OPS (VM 607) | 2224 | 10.100.165.10 (proposée) |
| DB1 | 2225 | 10.100.166.3 |
| DB2 | 2226 | 10.100.166.4 |
| DB3 | 2227 | 10.100.166.5 |
| WEB2 | 2228 | 10.100.164.3 (à vérifier) |
| HAProxy | 2253 | 10.100.164.2 (à vérifier) |

Les redirections se créent dans pfSense (procédure 02, §4.5). Leur port de destination (22) est présumé.

## 3. Prérequis

- Redirections NAT en place sur pfSense.
- Un poste d'administration sur le réseau de l'école, avec un client OpenSSH.
- Un compte d'administration sur chaque VM : `<UTILISATEUR>`.

## 4. Procédure

### 4.1 Générer une clé sur le poste d'administration

```bash
ssh-keygen -t ed25519 -C "admin-labo-sisr"
```

Protéger la clé privée par une phrase secrète. La clé privée (`id_ed25519`) ne quitte jamais le poste et ne va **jamais** dans Git. Seule la clé publique (`id_ed25519.pub`) se copie.

### 4.2 Déclarer les machines dans `~/.ssh/config`

```text
Host adpsqs
    HostName 10.2.0.198
    Port 2222
    User <UTILISATEUR>

Host web1
    HostName 10.2.0.198
    Port 2223
    User <UTILISATEUR>

Host ops
    HostName 10.2.0.198
    Port 2224
    User <UTILISATEUR>

Host db1
    HostName 10.2.0.198
    Port 2225
    User <UTILISATEUR>

Host db2
    HostName 10.2.0.198
    Port 2226
    User <UTILISATEUR>

Host db3
    HostName 10.2.0.198
    Port 2227
    User <UTILISATEUR>

Host web2
    HostName 10.2.0.198
    Port 2228
    User <UTILISATEUR>

Host haproxy
    HostName 10.2.0.198
    Port 2253
    User <UTILISATEUR>

Host *
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Ensuite, `ssh db1` suffit.

### 4.3 Installer la clé publique sur chaque machine Linux

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub db1
```

À répéter pour `web1`, `web2`, `db2`, `db3`, `haproxy` et `ops`. Cette étape demande le mot de passe une dernière fois.

### 4.4 Interdire le mot de passe sur chaque machine Linux

Debian lit les fichiers du dossier `sshd_config.d` avant le fichier principal : un fichier préfixé `10-` prend le dessus.

```bash
sudo tee /etc/ssh/sshd_config.d/10-labo.conf > /dev/null <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
EOF

sudo sshd -t && sudo systemctl reload ssh
```

**Avant de fermer la session en cours**, ouvrir une seconde connexion pour vérifier que la clé fonctionne. Si l'accès actuel passe par `root`, adapter `PermitRootLogin` d'abord (à vérifier).

### 4.5 ADPSQS (Windows Server) : OpenSSH Server

Le mécanisme réellement utilisé sur ADPSQS est à vérifier. Mise en place de référence, en PowerShell administrateur :

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
```

Pour un compte administrateur, la clé publique se place dans `C:\ProgramData\ssh\administrators_authorized_keys`, avec des droits restreints :

```powershell
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

Puis, dans `C:\ProgramData\ssh\sshd_config`, mettre `PasswordAuthentication no` et redémarrer le service : `Restart-Service sshd`.

## 5. Vérification

| Test | Commande | Résultat attendu |
| --- | --- | --- |
| Connexion par clé | `ssh web1 hostname` | Nom de la machine, sans mot de passe |
| Mot de passe refusé | `ssh -o PubkeyAuthentication=no web1` | `Permission denied (publickey)` |
| Une machine par port | `ssh -p 2225 <UTILISATEUR>@10.2.0.198 hostname` | `db1` |
| Journal des connexions | `journalctl -u ssh -n 20` sur la machine | Connexion acceptée avec l'adresse source |
| Échecs visibles | Tentative avec une mauvaise clé, puis `journalctl -u ssh` | Ligne d'échec avec l'adresse source |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | Clés d'hôte régénérées après clonage, ou deux VM qui partagent les mêmes clés | Voir ci-dessous |
| `Permission denied (publickey)` | Clé non copiée, ou droits trop larges sur `~/.ssh` | `chmod 700 ~/.ssh` et `chmod 600 ~/.ssh/authorized_keys` sur la VM |
| `Connection timed out` | Redirection NAT absente, règle pfSense manquante, VM éteinte | Procédure 02, §4.5 ; vérifier l'état de la VM |
| `Connection refused` | `sshd` arrêté sur la VM | Console Proxmox : `systemctl status ssh` |

Comme toutes les machines partagent l'adresse `10.2.0.198`, `known_hosts` enregistre chaque machine sous la forme `[10.2.0.198]:<port>`. Pour effacer une entrée :

```bash
ssh-keygen -R "[10.2.0.198]:2223"
```

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/ssh/` :

- `01-connexion-par-cle.png` : connexion sans mot de passe.
- `02-mot-de-passe-refuse.png` : `Permission denied (publickey)`.
- `03-journal-ssh.png` : connexions acceptées et refusées dans `journalctl -u ssh`.
- Trace texte : section « ssh » de chaque fichier `annexes/captures/<technologie>/AAAA-MM-JJ-<hôte>-etat.txt` (réglages effectifs, connexions des 7 derniers jours), relevée par `annexes/scripts/collecte-preuves.sh`.

## 8. Suite prévue

En phase 3, l'administration passe par le bastion Guacamole (NAT 8443 vers OPS, flux F17 et F25). Les redirections 2222 à 2228 et 2253 sont supprimées après validation du bastion ; la console Proxmox reste le secours.

## 9. Points à vérifier

- [ ] Chaque redirection vise bien le port 22.
- [ ] Mécanisme SSH réel sur ADPSQS.
- [ ] Compte d'administration utilisé sur chaque VM et réglage de `PermitRootLogin`.

## 10. Références

- Page de manuel `sshd_config(5)`, OpenSSH.
- [Notes de version de Debian 12](https://www.debian.org/releases/bookworm/amd64/release-notes/ch-information.en.html), Debian (journalisation avec `journalctl`).
