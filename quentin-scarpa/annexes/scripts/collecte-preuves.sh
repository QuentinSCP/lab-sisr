#!/usr/bin/env bash
# Relève l'état réel du labo et ses configurations, pour les preuves du dossier E6.
#
# Usage : annexes/scripts/collecte-preuves.sh [HÔTE ...]   (par défaut : haproxy web1 web2 db1 db2 db3)
# À lancer depuis le poste d'administration (Linux, macOS ou WSL) avec les alias SSH
# de la procédure 03. sudo peut demander le mot de passe une fois par machine.
#
# Produit :
#   annexes/captures/<technologie>/AAAA-MM-JJ-<hôte>-etat.txt   versions, services, indicateurs, journaux
#   annexes/scripts/<technologie>/...                            fichiers relevés sur les machines, secrets masqués
#   annexes/captures/haproxy/AAAA-MM-JJ-poste-admin.txt          le site vu depuis le poste d'administration
# Relire « git diff » avant de committer : les sorties contiennent les adresses IP du labo.
set -euo pipefail

cd "$(dirname "$0")/../.."   # racine du rendu
SITE=${SITE:-http://10.2.0.198:8081/}
JOUR=$(date +%F)
HOTES=("$@")
[ ${#HOTES[@]} -gt 0 ] || HOTES=(haproxy web1 web2 db1 db2 db3)

# Masque les secrets connus avant d'écrire dans le dépôt.
masquer() {
    sed -E \
        -e 's/^([[:space:]]*stats[[:space:]]+auth[[:space:]]+).*/\1<UTILISATEUR>:<MOT_DE_PASSE>/' \
        -e 's/^([[:space:]]*wsrep_sst_auth[[:space:]]*=).*/\1<UTILISATEUR>:<MOT_DE_PASSE>/' \
        -e 's/^([[:space:]]*auth_pass[[:space:]]+).*/\1<MOT_DE_PASSE>/' \
        -e 's/^([[:space:]]*(password|passwd|pass)[[:space:]]*=).*/\1<MOT_DE_PASSE>/'
}

# Commandes lancées en root sur chaque machine, puis selon son rôle.
COMMUN=$(cat <<'FIN'
exec 2>&1
t() { printf '\n==== %s ====\n' "$*"; }
t machine
hostname; date --iso-8601=seconds; cat /etc/debian_version; uptime
t adresses et routes
ip -br a; ip route
t mémoire et disque
free -h; df -h /
t "ssh : réglages effectifs"
sshd -T | grep -E '^(passwordauthentication|pubkeyauthentication|permitrootlogin) '
t "ssh : connexions des 7 derniers jours"
journalctl -u ssh --since -7d --no-pager | grep -E 'Accepted|Failed|Invalid' | tail -n 20
FIN
)

HAPROXY=$(cat <<'FIN'
t version
haproxy -v | head -n 1
t configuration
haproxy -c -f /etc/haproxy/haproxy.cfg
t ports en écoute
ss -ltnp | grep haproxy
t "état des serveurs : proxy, serveur, sessions cumulées, redistributions, état"
echo "show stat" | socat stdio /run/haproxy/admin.sock | cut -d, -f1,2,8,17,18
t "journal : serveurs retirés ou réintégrés (7 jours)"
journalctl -u haproxy --since -7d --no-pager | grep -E 'is (UP|DOWN)' | tail -n 30
FIN
)

WEB=$(cat <<'FIN'
t versions
apache2 -v | head -n 1; php -v | head -n 1
t configuration apache
apache2ctl configtest
t réponse locale
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1/
t "codes HTTP dans access.log"
awk '{print $9}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head
t dernières erreurs
tail -n 20 /var/log/apache2/error.log
t "empreinte de wp-config.php (identique sur web1 et web2 ?)"
sha256sum /var/www/html/wp-config.php
FIN
)

DB=$(cat <<'FIN'
t version
mariadb --version
t indicateurs galera
mariadb -e "SHOW GLOBAL STATUS WHERE Variable_name IN ('wsrep_cluster_size','wsrep_cluster_status','wsrep_local_state_comment','wsrep_ready','wsrep_connected','wsrep_last_committed')"
t "contrôle de santé, port 9200"
curl -s -i --max-time 3 http://127.0.0.1:9200/ || echo "pas de réponse sur le port 9200"
t grastate.dat
cat /var/lib/mysql/grastate.dat
t "journal mariadb : galera (7 jours)"
journalctl -u mariadb --since -7d --no-pager | grep -iE 'wsrep|galera' | tail -n 30
FIN
)

for h in "${HOTES[@]}"; do
    case "$h" in
        haproxy*) role=$HAPROXY; tech=haproxy ;;
        web*)     role=$WEB;     tech=wordpress ;;
        db*)      role=$DB;      tech=galera ;;
        *)        role="";       tech=autres ;;
    esac
    mkdir -p "annexes/captures/$tech"
    fichier=annexes/captures/$tech/$JOUR-$h-etat.txt
    brut=$(mktemp)
    b64=$(printf '%s\n%s\n' "$COMMUN" "$role" | base64 | tr -d '\n')
    echo "== $h"
    # -t : sudo peut demander son mot de passe ; la sortie passe alors par un terminal (\r à retirer)
    ssh -qt "$h" "sudo bash -c \"\$(echo $b64 | base64 -d)\"" | tee "$brut" || echo "(échec de la connexion à $h)"
    tr -d '\r' < "$brut" | grep -v '^\[sudo\] ' > "$fichier" || true
    rm -f "$brut"
    echo "état : $fichier"
done

# Fichiers lisibles sans sudo : hôte, chemin sur la machine, chemin dans le dépôt
FICHIERS="
haproxy /etc/haproxy/haproxy.cfg annexes/scripts/haproxy/haproxy.cfg
haproxy /etc/keepalived/keepalived.conf annexes/scripts/haproxy/keepalived.conf
web1 /etc/apache2/conf-available/wordpress.conf annexes/scripts/apache/wordpress.conf
web1 /etc/apache2/conf-available/remoteip.conf annexes/scripts/apache/remoteip.conf
web1 /etc/apache2/conf-available/served-by.conf annexes/scripts/apache/web1-served-by.conf
web2 /etc/apache2/conf-available/served-by.conf annexes/scripts/apache/web2-served-by.conf
db1 /etc/mysql/mariadb.conf.d/60-galera.cnf annexes/scripts/galera/db1-60-galera.cnf
db2 /etc/mysql/mariadb.conf.d/60-galera.cnf annexes/scripts/galera/db2-60-galera.cnf
db3 /etc/mysql/mariadb.conf.d/60-galera.cnf annexes/scripts/galera/db3-60-galera.cnf
db1 /etc/systemd/system/galera-check.socket annexes/scripts/galera/galera-check.socket
db1 /etc/systemd/system/galera-check@.service annexes/scripts/galera/galera-check@.service
db1 /usr/local/bin/galera-check.sh annexes/scripts/galera/galera-check.sh
db3 /usr/local/bin/sauvegarde-sql.sh annexes/scripts/galera/sauvegarde-sql.sh
db3 /etc/cron.d/sauvegarde-sql annexes/scripts/galera/cron-sauvegarde-sql
"
while read -r h distant local; do
    [ -n "$h" ] || continue
    case " ${HOTES[*]} " in *" $h "*) ;; *) continue ;; esac
    # -n : ssh ne doit pas lire la liste des fichiers sur l'entrée standard
    if contenu=$(ssh -n -o BatchMode=yes "$h" cat "$distant" 2>/dev/null); then
        mkdir -p "$(dirname "$local")"
        printf '%s\n' "$contenu" | masquer > "$local"
        echo "relevé : $local"
    else
        echo "absent ou illisible sur $h : $distant"
    fi
done <<< "$FICHIERS"

mkdir -p annexes/captures/haproxy
{
    echo "==== $JOUR : site par le NAT, $SITE ===="
    curl -sS -I --max-time 5 "$SITE" || true
    echo "==== répartition : 10 requêtes (en-tête X-Served-By, procédure 05 §4.7) ===="
    for _ in $(seq 1 10); do
        curl -s -o /dev/null -D - --max-time 5 "$SITE" | grep -i '^x-served-by' || echo "(pas d'en-tête X-Served-By)"
    done | tr -d '\r' | sort | uniq -c
} | tr -d '\r' | tee "annexes/captures/haproxy/$JOUR-poste-admin.txt"

echo "Terminé. Relire « git diff » avant de committer."
