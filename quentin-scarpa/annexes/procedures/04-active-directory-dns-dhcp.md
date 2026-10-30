# 04 · Active Directory, DNS et DHCP

| | |
| --- | --- |
| **Machine(s)** | `ADPSQS` (VM 606) |
| **Zone et adresse** | ADM (VLAN 165), `10.100.165.1` |
| **État** | Partiel : domaine et DNS en place mais peu exploités, DHCP à venir |
| **Référence DAT** | §2, §8, §12 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer au script réel avant de les citer comme preuve dans le dossier E6.

## 1. Objectif et périmètre

ADPSQS porte le domaine `qscarpa.lan`, le DNS interne et le DHCP. Il fournit comptes, noms et adresses à tout le laboratoire. Cette procédure couvre l'installation, la déclaration des serveurs dans le DNS, l'étendue DHCP de la zone USERS et la structure de l'annuaire. Les rôles ajoutés par Sentinelle (LDAPS, autorité interne, FS01) auront leur propre procédure.

## 2. Valeurs du laboratoire

| Élément | Valeur | Source |
| --- | --- | --- |
| Système | Windows Server 2022 (version à relever avec `winver`) | DAT §6 |
| Nom et adresse | `ADPSQS`, `10.100.165.1/24`, passerelle `10.100.165.254` | DAT §6 et §7 |
| Domaine | `qscarpa.lan` | DAT §8 |
| Zone USERS | `10.100.167.0/24`, DHCP de `.100` à `.199`, passerelle `.254` | DAT §7 (plage proposée) |
| Redirecteur DNS | `<DNS_ECOLE>` | À vérifier (`Get-DnsServerForwarder`) |

## 3. Prérequis

- VM Windows Server 2022 dans le VLAN 165 (procédure 01).
- Un compte administrateur local et un mot de passe DSRM (mode de restauration des services d'annuaire) à noter hors du dépôt.
- Flux F7 (DNS), F8 (DHCP relayé) et F9 (ouverture de session) ouverts sur pfSense (procédure 02).

## 4. Procédure

Toutes les commandes se lancent dans PowerShell, en administrateur.

### 4.1 Nom et adresse

```powershell
Rename-Computer -NewName 'ADPSQS' -Restart
```

Après le redémarrage :

```powershell
New-NetIPAddress -InterfaceAlias '<INTERFACE>' -IPAddress 10.100.165.1 -PrefixLength 24 -DefaultGateway 10.100.165.254
Set-DnsClientServerAddress -InterfaceAlias '<INTERFACE>' -ServerAddresses 127.0.0.1
```

`<INTERFACE>` se lit avec `Get-NetAdapter`.

### 4.2 Installer les rôles et créer le domaine

Installation de référence du DAT (§8), à comparer au script réel :

```powershell
Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools
Install-ADDSForest -DomainName 'qscarpa.lan' -InstallDns
```

`Install-ADDSForest` demande le mot de passe DSRM de façon interactive : il n'est écrit dans aucun script. Le serveur redémarre à la fin. Le script réel est à verser dans `annexes/scripts/` (sans mot de passe).

### 4.3 DNS : redirecteur et zones inverses

```powershell
Get-DnsServerForwarder
Set-DnsServerForwarder -IPAddress <DNS_ECOLE>
```

Une zone inverse par VLAN permet les enregistrements PTR :

```powershell
Add-DnsServerPrimaryZone -NetworkId '10.100.164.0/24' -ReplicationScope 'Forest'
Add-DnsServerPrimaryZone -NetworkId '10.100.165.0/24' -ReplicationScope 'Forest'
Add-DnsServerPrimaryZone -NetworkId '10.100.166.0/24' -ReplicationScope 'Forest'
```

### 4.4 DNS : déclarer chaque serveur

Les serveurs Linux ne sont pas déclarés : c'est la cause de l'erreur WordPress E03 de la matrice d'erreurs (DAT §8). ADPSQS s'enregistre seul.

```powershell
$serveurs = @(
    @{ Nom = 'web1';    Ip = '10.100.164.1' },
    @{ Nom = 'haproxy'; Ip = '10.100.164.2' },
    @{ Nom = 'web2';    Ip = '10.100.164.3' },
    @{ Nom = 'db1';     Ip = '10.100.166.3' },
    @{ Nom = 'db2';     Ip = '10.100.166.4' },
    @{ Nom = 'db3';     Ip = '10.100.166.5' }
)

foreach ($s in $serveurs) {
    Add-DnsServerResourceRecordA -ZoneName 'qscarpa.lan' -Name $s.Nom -IPv4Address $s.Ip -CreatePtr
}
```

Les adresses de `haproxy` et `web2` sont à vérifier (DAT §18). Vérifier avec `nslookup` **avant** de remplacer une adresse IP par un nom dans une configuration (DAT §12).

### 4.5 Pointer les VM Linux vers ADPSQS

Sur chaque VM Linux, dans `/etc/resolv.conf` :

```text
search qscarpa.lan
nameserver 10.100.165.1
```

Si ce fichier est géré par un autre outil (`resolvconf`, `systemd-resolved`), le modifier là où l'outil le demande : sinon la valeur est perdue au redémarrage (à vérifier sur les VM).

### 4.6 DHCP : autoriser le serveur et créer l'étendue USERS

```powershell
Add-DhcpServerInDC -DnsName 'adpsqs.qscarpa.lan' -IPAddress 10.100.165.1
Add-DhcpServerSecurityGroup
Restart-Service dhcpserver

Add-DhcpServerv4Scope -Name 'USERS' -StartRange 10.100.167.100 -EndRange 10.100.167.199 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -ScopeId 10.100.167.0 -Router 10.100.167.254 -DnsServer 10.100.165.1 -DnsDomain 'qscarpa.lan'
```

Le serveur DHCP est dans le VLAN 165, les postes dans le VLAN 167 : pfSense doit **relayer** les demandes vers `10.100.165.1` (procédure 02, §8) et son propre serveur DHCP doit être coupé sur USERS.

### 4.7 Structurer l'annuaire

État actuel : annuaire peu exploité. Structure proposée : une OU par usage, des groupes, des comptes nominatifs et des comptes de service.

```powershell
$base = 'DC=qscarpa,DC=lan'

New-ADOrganizationalUnit -Name 'Labo' -Path $base
foreach ($ou in 'Utilisateurs', 'Groupes', 'Serveurs', 'Postes', 'ComptesService') {
    New-ADOrganizationalUnit -Name $ou -Path "OU=Labo,$base"
}
```

Modèle **AGDLP** (comptes, groupes globaux, groupes locaux de domaine, permissions), prévu pour FS01 :

```powershell
$service = 'Conseil'   # exemple : un service du cabinet fictif

New-ADGroup -Name "GG_$service"    -GroupScope Global      -Path "OU=Groupes,OU=Labo,$base"
New-ADGroup -Name "DL_${service}_RW" -GroupScope DomainLocal -Path "OU=Groupes,OU=Labo,$base"
Add-ADGroupMember -Identity "DL_${service}_RW" -Members "GG_$service"
```

Un compte nominatif, ajouté au groupe global de son service :

```powershell
New-ADUser -Name '<PRENOM NOM>' -SamAccountName '<identifiant>' `
    -UserPrincipalName '<identifiant>@qscarpa.lan' `
    -Path "OU=Utilisateurs,OU=Labo,$base" `
    -AccountPassword (Read-Host -Prompt 'Mot de passe initial' -AsSecureString) `
    -ChangePasswordAtLogon $true -Enabled $true

Add-ADGroupMember -Identity "GG_$service" -Members '<identifiant>'
```

### 4.8 Stratégies de groupe de base

Politique de mot de passe et de verrouillage du domaine (valeurs proposées, à valider) :

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity 'qscarpa.lan' `
    -MinPasswordLength 12 -ComplexityEnabled $true `
    -LockoutThreshold 5 -LockoutDuration 00:15:00 -LockoutObservationWindow 00:15:00
```

Verrouillage de session après 15 minutes d'inactivité, par une GPO liée à l'OU des postes :

```powershell
New-GPO -Name 'GPO-Base-Postes' | New-GPLink -Target "OU=Postes,OU=Labo,$base"
Set-GPRegistryValue -Name 'GPO-Base-Postes' `
    -Key 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System' `
    -ValueName 'InactivityTimeoutSecs' -Type DWord -Value 900
```

### 4.9 Joindre un poste Windows au domaine

Sur le poste du VLAN 167, une fois son DNS fourni par le DHCP :

```powershell
Add-Computer -DomainName 'qscarpa.lan' -Credential 'QSCARPA\<ADMIN>' -OUPath "OU=Postes,OU=Labo,DC=qscarpa,DC=lan" -Restart
```

Puis, sur le poste : `gpupdate /force` et `gpresult /r`.

### 4.10 Heure du domaine

Kerberos refuse les sessions au-delà de 5 minutes d'écart (DAT §20). L'état du NTP est à vérifier :

```powershell
w32tm /query /status
w32tm /config /manualpeerlist:"<SOURCE_NTP>" /syncfromflags:manual /reliable:yes /update
Restart-Service w32time
```

## 5. Vérification

| Test | Commande | Résultat attendu |
| --- | --- | --- |
| Domaine | `Get-ADDomain` | `qscarpa.lan` |
| Santé de l'annuaire | `dcdiag /q` | Aucune erreur |
| Services | `Get-Service NTDS, DNS, DHCPServer, Netlogon` | `Running` |
| Nom direct | `nslookup web1.qscarpa.lan 10.100.165.1` | `10.100.164.1` |
| Nom inverse | `nslookup 10.100.164.1 10.100.165.1` | `web1.qscarpa.lan` |
| Depuis une VM Linux | `getent hosts web1.qscarpa.lan` | `10.100.164.1` |
| Étendue DHCP | `Get-DhcpServerv4Scope` | Étendue `USERS`, active |
| Bail attribué | `Get-DhcpServerv4Lease -ScopeId 10.100.167.0` | Le poste client apparaît |
| GPO appliquée | `gpresult /r` sur le poste | `GPO-Base-Postes` listée |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| WordPress affiche l'erreur E03 | Serveur absent du DNS | §4.4 |
| Le poste ne trouve pas le domaine | Son DNS ne pointe pas vers `10.100.165.1` | Contrôler les options DHCP (`Set-DhcpServerv4OptionValue`) |
| Aucun bail DHCP | Relais pfSense absent, ou DHCP de pfSense encore actif sur USERS | Procédure 02, §8 |
| Ouverture de session refusée | Écart d'heure supérieur à 5 minutes | §4.10 |
| Le serveur DHCP ne démarre pas ses baux | Serveur non autorisé dans l'annuaire | `Add-DhcpServerInDC` (§4.6) |

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/active-directory/` :

- `01-utilisateurs-et-ordinateurs.png` : arborescence des OU et des groupes.
- `02-zone-dns-directe-et-inverse.png` : enregistrements A et PTR des serveurs.
- `03-etendue-dhcp-users.png` : étendue et options.
- `04-gpresult-poste.png` : GPO appliquée sur un poste.
- `05-journal-securite-4624-4625.png` : ouvertures de session réussies et échouées.

## 8. Points à vérifier

- [ ] Script d'installation réel, à comparer au §4.2 et à verser dans `annexes/scripts/`.
- [ ] Redirecteur DNS (`Get-DnsServerForwarder`).
- [ ] État du relais DHCP sur pfSense.
- [ ] Version de Windows Server (`winver`) et licence (évaluation ou licence de l'école).
- [ ] Synchronisation de l'heure (NTP).

## 9. Références

- [Installer AD DS](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-), Microsoft.
- [Ports réseau de Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements), Microsoft.
- [Relais DHCP](https://docs.netgate.com/pfsense/en/latest/services/dhcp/relay.html), pfSense.
