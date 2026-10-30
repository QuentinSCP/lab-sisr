# 05 · Apache, PHP et WordPress

| | |
| --- | --- |
| **Machine(s)** | `WEB1` (VM 609), `WEB2` (VM 615) |
| **Zone et adresse** | WEB (VLAN 164), `10.100.164.1` et `10.100.164.3` (WEB2 à vérifier) |
| **État** | En place |
| **Référence DAT** | §9, §12, §20 |

> Procédure de référence rédigée à partir du DAT v1.4. Les valeurs marquées *à vérifier* ne sont pas relevées sur la machine : les comparer à l'état réel avant de les citer comme preuve dans le dossier E6.

## 1. Objectif et périmètre

Deux serveurs web identiques publient le même site WordPress. HAProxy répartit les requêtes entre eux ; WordPress lit et écrit dans la base par HAProxy, qui l'envoie au nœud Galera principal. Cette procédure couvre un serveur ; elle se rejoue sur le second.

## 2. Valeurs du laboratoire

| Élément | Valeur | Source |
| --- | --- | --- |
| Serveur web | Apache 2, PHP, module `rewrite` | DAT §11 |
| Racine web | `/var/www/html` | Défaut Debian |
| Base de données | `wp2026`, compte limité à cette base | DAT §13 |
| `DB_HOST` | `10.100.164.2` (HAProxy) | DAT §9 |
| `WP_HOME` et `WP_SITEURL` | `http://10.2.0.198:8081` | DAT §9 |
| Accès public | `http://10.2.0.198:8081` (NAT pfSense vers HAProxy) | DAT §7, F1 |

## 3. Prérequis

- VM Debian dans le VLAN 164 avec adresse fixe (procédure 01).
- Cluster Galera, base `wp2026` et compte WordPress créés (procédure 06, §4.6).
- HAProxy en service sur `10.100.164.2`, écoute SQL incluse (procédure 07).
- Flux ouverts : F2 (HAProxy vers Apache), F3 (WordPress vers HAProxy, port 3306).

## 4. Procédure

### 4.1 Installer Apache et PHP

```bash
sudo apt update
sudo apt install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd \
    php-mbstring php-xml php-zip php-intl mariadb-client
sudo a2enmod rewrite
```

`mariadb-client` sert uniquement à tester la connexion à la base (§5).

### 4.2 Autoriser les fichiers `.htaccess`

WordPress écrit ses règles de réécriture dans `.htaccess` : Apache doit les lire.

```bash
sudo tee /etc/apache2/conf-available/wordpress.conf > /dev/null <<'EOF'
<Directory /var/www/html>
    AllowOverride All
</Directory>
EOF

sudo a2enconf wordpress
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### 4.3 Télécharger et installer WordPress

```bash
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
curl -O https://wordpress.org/latest.tar.gz.sha1
echo "$(cat latest.tar.gz.sha1)  latest.tar.gz" | sha1sum -c -

tar -xzf latest.tar.gz
sudo rm -f /var/www/html/index.html
sudo cp -a wordpress/. /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
```

La ligne `sha1sum -c` doit afficher `latest.tar.gz: OK`.

### 4.4 Configurer `wp-config.php`

```bash
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo nano /var/www/html/wp-config.php
```

Valeurs à renseigner :

```php
define( 'DB_NAME', 'wp2026' );
define( 'DB_USER', '<UTILISATEUR_WP>' );
define( 'DB_PASSWORD', '<MOT_DE_PASSE>' );
define( 'DB_HOST', '10.100.164.2' );
define( 'DB_CHARSET', 'utf8mb4' );

define( 'WP_HOME',    'http://10.2.0.198:8081' );
define( 'WP_SITEURL', 'http://10.2.0.198:8081' );

// Clés et sels : remplacer les huit lignes d'exemple par le résultat de
// https://api.wordpress.org/secret-key/1.1/salt/
```

`DB_HOST` vise HAProxy, **pas** un nœud Galera : c'est HAProxy qui choisit le nœud. `WP_HOME` et `WP_SITEURL` valent l'adresse vue depuis le réseau de l'école, pas l'adresse interne du serveur.

Ce fichier contient des secrets : il n'est **jamais** versionné (le `.gitignore` le bloque). Dans `annexes/scripts/`, ne verser qu'une copie `wp-config.sample.php` avec les mêmes valeurs entre chevrons.

### 4.5 Lancer l'installation WordPress (une seule fois)

Depuis un navigateur du réseau de l'école : `http://10.2.0.198:8081/wp-admin/install.php`. Renseigner le titre du site et un compte administrateur nominatif. La base étant partagée, l'installation ne se fait **qu'une fois**, pas sur chaque serveur.

### 4.6 Répliquer sur le second serveur

Rejouer les étapes 4.1 et 4.2 sur WEB2, puis copier les fichiers de WEB1, `wp-config.php` compris :

```bash
# Sur WEB1
sudo tar -C /var/www/html -czf /tmp/wordpress-site.tgz .
scp /tmp/wordpress-site.tgz <UTILISATEUR>@10.100.164.3:/tmp/

# Sur WEB2
sudo tar -C /var/www/html -xzf /tmp/wordpress-site.tgz
sudo chown -R www-data:www-data /var/www/html
```

Les deux `wp-config.php` doivent être **identiques**, clés et sels compris. Sinon, changer de serveur invalide les cookies de connexion et l'utilisateur est déconnecté (DAT §9).

### 4.7 Voir quelle machine répond (optionnel, utile aux tests)

Un en-tête indique quel serveur a servi la page :

```bash
sudo a2enmod headers
echo 'Header always set X-Served-By "web1"' | sudo tee /etc/apache2/conf-available/served-by.conf
sudo a2enconf served-by
sudo systemctl reload apache2
```

Sur WEB2, remplacer `web1` par `web2`. Ce fichier **diffère** d'un serveur à l'autre : ne pas le copier avec le site.

### 4.8 Journaliser l'adresse réelle du client (optionnel)

Sans réglage, l'accès Apache affiche l'adresse de HAProxy. Pour la vraie adresse (utile à la détection de force brute) :

```bash
sudo a2enmod remoteip
sudo tee /etc/apache2/conf-available/remoteip.conf > /dev/null <<'EOF'
RemoteIPHeader X-Forwarded-For
RemoteIPTrustedProxy 10.100.164.2
EOF
sudo a2enconf remoteip
sudo systemctl reload apache2
```

HAProxy ajoute déjà l'en-tête (`option forwardfor`, procédure 07).

### 4.9 Fichiers téléversés : point ouvert

Les fichiers de `wp-content/uploads` n'existent que sur le serveur qui les a reçus : une image ajoutée via WEB1 manque sur WEB2. Un partage commun (NFS) ou une synchronisation reste à choisir (DAT §9 et §18). Tant que ce n'est pas résolu, limiter les ajouts de médias ou les faire sur les deux serveurs.

## 5. Vérification

| Test | Commande | Résultat attendu |
| --- | --- | --- |
| Configuration Apache | `sudo apache2ctl configtest` | `Syntax OK` |
| Service | `systemctl status apache2` | `active (running)` |
| Chaque serveur répond | `curl -I http://10.100.164.1` puis `.3` | `200` ou `302` |
| Base joignable par HAProxy | `mariadb -h 10.100.164.2 -u <UTILISATEUR_WP> -p wp2026 -e 'SELECT 1'` | Une ligne `1` |
| Par le NAT | `curl -I http://10.2.0.198:8081` depuis l'école | `200` ou `302` |
| Répartition | `for i in 1 2 3 4; do curl -s -D - -o /dev/null http://10.2.0.198:8081/ \| grep -i x-served-by; done` | `web1` et `web2` en alternance |
| Panne d'un serveur | `sudo systemctl stop apache2` sur WEB1, puis `curl -I` par le NAT | Toujours `200`, servi par WEB2 (tests T08 et T10) |

## 6. Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| `Error establishing a database connection` | Compte créé pour la mauvaise adresse, flux F3 ou F4 fermé, base arrêtée | Tester avec `mariadb -h 10.100.164.2 ...` ; le compte doit exister pour `10.100.164.2` (procédure 06) |
| Erreur WordPress E03 | Serveurs Linux absents du DNS | Procédure 04, §4.4 |
| Redirection en boucle ou mauvaise adresse | `WP_HOME` ou `WP_SITEURL` incorrects | Remettre `http://10.2.0.198:8081` |
| Déconnexion en changeant de serveur | `wp-config.php` différents entre WEB1 et WEB2 | Recopier le fichier, clés et sels compris |
| Image manquante sur un seul serveur | Téléversement non partagé | §4.9 |
| Permaliens en `404` | `rewrite` désactivé ou `AllowOverride None` | §4.1 et §4.2 |
| Page blanche | Erreur PHP | `sudo tail /var/log/apache2/error.log` |

## 7. Preuves à conserver pour le dossier E6

Captures à déposer dans `annexes/captures/wordpress/` :

- `01-site-par-nat.png` : le site ouvert sur `http://10.2.0.198:8081`.
- `02-repartition-web1-web2.png` : l'en-tête `X-Served-By` en alternance.
- `03-panne-web1.png` : Apache arrêté sur WEB1, site toujours en ligne.
- `04-journal-apache.png` : extrait commenté de `access.log`.
- Traces texte : `annexes/captures/wordpress/AAAA-MM-JJ-web1-etat.txt` et `-web2-etat.txt` (versions, codes HTTP, empreinte de `wp-config.php`), relevées par `annexes/scripts/collecte-preuves.sh` ; mesures de panne dans `annexes/captures/bascules/` (`annexes/scripts/mesure-bascule.sh`, procédure 08).

## 8. Points à vérifier

- [ ] Version de Debian et de PHP sur chaque serveur.
- [ ] Adresse de WEB2 (`10.100.164.3` retenue ici).
- [ ] Solution retenue pour `wp-content/uploads` (NFS ou synchronisation).
- [ ] Identité des deux `wp-config.php` (clés et sels).
- [ ] HTTPS sur le site (à venir) : prévoir `WP_HOME` en `https` et l'en-tête `X-Forwarded-Proto` (DAT §12).

## 9. Références

- [Fichier `wp-config.php`](https://developer.wordpress.org/apis/wp-config-php/), WordPress.
- [Adresses du site](https://developer.wordpress.org/advanced-administration/wordpress/wp-config/), WordPress.
