#!/usr/bin/env bash
# Mesure la disponibilité du site pendant une panne provoquée (plan de tests R1).
#
# Usage :
#   annexes/scripts/mesure-bascule.sh [URL] [DUREE_S] [NOM]   mesure, puis résumé
#   annexes/scripts/mesure-bascule.sh --analyse FICHIER.csv    résumé d'une mesure existante
#   annexes/scripts/mesure-bascule.sh --test                   vérifie le calcul du résumé
#
# Une requête toutes les 0,5 s. Échec : code HTTP hors 2xx et 3xx, ou pas de réponse en 2 s.
# Pendant la mesure, provoquer la panne dans un second terminal,
# par exemple : ssh web1 sudo systemctl stop apache2
# Produit : annexes/captures/bascules/AAAA-MM-JJ-HHMMSS-NOM.csv et le résumé -resume.txt à côté.
set -euo pipefail
export LC_ALL=C   # point décimal pour l'horodatage et pour awk

# Plus longue interruption : de la première requête en échec à la réussite suivante.
analyse() {
    awk -F';' '
        NR == 1 { next }
        { n++; t = $1 }
        $3 ~ /^[23]/ { ok++; if (debut != "") { if (t - debut > max) max = t - debut; debut = "" }; next }
        { ko++; if (debut == "") debut = t }
        END {
            if (debut != "" && t - debut > max) max = t - debut
            printf "requêtes : %d · réussies : %d · en échec : %d · plus longue interruption : %.1f s\n", n, ok, ko, max
        }' "$1"
}

case "${1:-}" in
    --analyse)
        analyse "$2"
        exit 0
        ;;
    --test)
        f=$(mktemp)
        printf '%s\n' 'horodatage;heure;code_http;serveur;duree_s' \
            '100.0;x;200;web1;0.01' '100.5;x;503;-;0.01' '101.0;x;000;-;2.00' \
            '103.0;x;200;web2;0.01' '103.5;x;200;web2;0.01' > "$f"
        obtenu=$(analyse "$f"); rm -f "$f"
        attendu='requêtes : 5 · réussies : 3 · en échec : 2 · plus longue interruption : 2.5 s'
        [ "$obtenu" = "$attendu" ] && { echo "test OK"; exit 0; }
        echo "test KO : $obtenu"; exit 1
        ;;
esac

URL=${1:-http://10.2.0.198:8081/}
DUREE=${2:-60}
NOM=${3:-mesure}

cd "$(dirname "$0")/../.."   # racine du rendu
mkdir -p annexes/captures/bascules
CSV=annexes/captures/bascules/$(date +%F-%H%M%S)-$NOM.csv
ENTETES=$(mktemp)
trap 'rm -f "$ENTETES"' EXIT

echo "Mesure de $URL pendant $DUREE s : provoquer la panne dans un autre terminal."
echo "horodatage;heure;code_http;serveur;duree_s" > "$CSV"
fin=$(( $(date +%s) + DUREE ))
while [ "$(date +%s)" -lt "$fin" ]; do
    t=${EPOCHREALTIME:-$(date +%s)}
    # -k : le certificat de l'autorité interne n'est pas vérifié pendant la mesure
    r=$(curl -sk -o /dev/null -D "$ENTETES" --max-time 2 -w '%{http_code};%{time_total}' "$URL" || true)
    # En-tête facultatif ajouté par Apache (procédure 05, §4.7)
    s=$(grep -i '^x-served-by:' "$ENTETES" | awk '{print $2}' | tr -d '\r' || true)
    ligne="$t;$(date +%T);${r%%;*};${s:--};${r#*;}"
    echo "$ligne" >> "$CSV"
    echo "$ligne" | cut -d';' -f2- | tr ';' ' '
    : > "$ENTETES"
    sleep 0.5
done

analyse "$CSV" | tee "${CSV%.csv}-resume.txt"
echo "Mesure : $CSV"
