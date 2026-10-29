# Table de correspondance : GSB et le laboratoire

Version 1.0 · 29 octobre 2026 · Quentin Scarpa

Le laboratoire garde son plan d'adressage et son domaine `qscarpa.lan` (conventions GSB, §1 et §2). Cette table relie les zones et les serveurs de GSB à leurs équivalents dans le labo. Elle sert d'annexe au [DAT d'environnement](dat-environnement.md) et au DAT de chaque réalisation ([DAT R1](dat-r1.md)).

## 1. Zones

| Zone de GSB | Rôle | Origine dans GSB | Équivalent dans le labo | Écart et raison |
| --- | --- | --- | --- | --- |
| Administration | Postes des techniciens réseau et système | VLAN 10 · 192.168.10.0/24 | Poste d'administration sur le réseau de l'école, qui passe par les redirections SSH de pfSense (alias `ADMIN_PC`) | Aucun poste d'administration dans le labo. Cible : bastion OPS en zone ADM (VLAN 165), réalisation 2 |
| Utilisateurs | Postes des services | VLAN 60 · 192.168.60.0/24 | USERS · VLAN 167 · 10.100.167.0/24 | Zone créée, poste Windows à venir |
| Visiteurs | Invités : DNS, DHCP et Internet seulement | VLAN 150 · 192.168.150.0/24 | Absente | À créer si une mission la demande (mission N4, lot 4 : limitation de débit). VLAN 168 proposé |
| Serveurs | Annuaire, bases de données, applications | VLAN 300 · 172.16.0.0/17 | Deux zones : ADM · VLAN 165 (annuaire et outils) et BDD · VLAN 166 (bases) | Plus strict que GSB : la base est séparée de l'annuaire et seul HAProxy la joint |
| Sortie | Liaison vers le pare-feu et Internet | VLAN 400 · 172.18.0.0/30 | Interface WAN de pfSense, 10.2.0.198, sur le réseau de l'école | Le réseau de l'école joue le rôle d'Internet |
| DMZ *(ajout)* | Services joignables depuis Internet | Absente | WEB · VLAN 164 · 10.100.164.0/24 : HAProxy, WEB1, WEB2 | Seule zone publiée (NAT 8081) |
| Site distant *(ajout)* | Réplication, VPN entre sites | Absent | Absent | Hors des réalisations prévues (mission N1, extension) |
| Visiteurs en déplacement *(ajout)* | Clients VPN | Absent | Absent | Hors des réalisations prévues (mission N1, lot 1) |

## 2. Règles de filtrage

| Règle d'origine de GSB | Transposition dans le labo | État |
| --- | --- | --- |
| Chaque zone, sauf Visiteurs, n'accède qu'aux zones Serveurs et Sortie | USERS n'atteint que les services d'ADM (F7 à F9, F18, F19) et Internet ; WEB n'atteint BDD que par HAProxy (F4, F5) ; BDD ne sort que pour ses mises à jour (F10) ; tout le reste est refusé et journalisé (F28) | Règles à comparer à la matrice (DAT §7) |
| Visiteurs : DNS, DHCP et Internet seulement | Pas de zone Visiteurs | Sans objet |
| *(ajout du labo)* ADM administre les autres zones, aucune ne l'administre | Les flux d'administration partent d'ADM (F14, F25) ou du poste d'administration par le NAT (F11) | F11 en place ; F14 et F25 à venir |

## 3. Serveurs

| Serveur de GSB | Rôle | Équivalent dans le labo | État |
| --- | --- | --- | --- |
| REZOLAB | DHCP et DNS | ADPSQS (VM 606, 10.100.165.1) : DNS de `qscarpa.lan` ; DHCP de USERS par le relais de pfSense | DNS partiel, DHCP à venir |
| LABANNU | Annuaire, contrôleur de domaine | ADPSQS : Active Directory, domaine `qscarpa.lan` | Partiel (pas encore d'OU, de groupes ni de GPO) |
| MESSAGLAB | Messagerie | Aucun | Absent |
| INTRALAB | Intranet | Aucun ; Nextcloud (COLLAB) prévu pour les fichiers et l'agenda | À venir |
| ProxSILAB | Proxy et pare-feu | pfSense (VM 611) | En place |
| MUTLAB | Routage entre VLAN, listes d'accès | pfSense : routage entre les VLAN et filtrage (pas de commutateur de niveau 3 dans le labo) | En place |
| RTROUT | Routeur et NAT | pfSense : NAT sortant et redirections ; la passerelle de l'école est en amont | En place |
| BDMEDOCLAB, BDPHARMA, BDMED | Bases de données | Grappe MariaDB Galera : DB1, DB2, DB3 (VLAN 166) | En place |
| Application de suivi des visites (`visite.gsb.coop`) | Application web des visiteurs | HAProxy (VM 616) devant WEB1 et WEB2, base sur la grappe Galera | En place avec WordPress comme charge de travail ; application de référence du formateur à déployer |

## 4. Valeurs communes

| Élément | Valeur de GSB | Valeur dans le labo |
| --- | --- | --- |
| Domaine | `gsbeu.intra` (environnement neuf seulement) | `qscarpa.lan`, conservé |
| Adresse de l'application | `visite.gsb.coop` | `http://10.2.0.198:8081` (HTTPS prévu en R1) |
| Visiteurs à servir | 480 en métropole | Charge simulée par `ab` (plan de tests R1, test R1-T10) |
