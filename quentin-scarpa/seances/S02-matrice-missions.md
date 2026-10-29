# Séance 2 — Matrice missions × compétences

**Étudiant :** Quentin · **Épreuve :** E6 SISR (BTS SIO) · **Date :** 29 octobre 2026 (rendu de S2, rédigé en S3)

*Pour chaque mission envisagée, ce que je pourrais **démontrer** à partir de mon laboratoire ([DAT d'environnement](../docs/dat-environnement.md)).*

| Mission | **Concevoir** : ce que je pourrais démontrer | **Installer** : ce que je pourrais démontrer | **Exploiter** : ce que je pourrais démontrer | Ressources dont j'aurai besoin |
|---|---|---|---|---|
| **N3 — Haute disponibilité** | Objectifs de reprise (RTO, RPO) justifiés ; choix entre réplication simple et grappe ; impact du répartiteur sur les comptes MariaDB et les flux ; plan de tests de bascule | HAProxy en HTTPS ; grappe Galera et contrôle de santé ; HAProxy2 et keepalived ; procédures de bascule | Administration par clé et journal ; délais de reprise mesurés ; exercice d'incident ; export logique restauré | Labo existant ; 1 VM (HAProxy2) ; autorité interne de pfSense ; `ab` |
| **N4 — Supervision et qualité de service** | Contrat de service ; indicateurs et seuils ; comparaison de deux outils (Prometheus avec Grafana, Zabbix) | Prometheus, Grafana, Alertmanager ; agents déployés par script ou Ansible ; limitation de débit sur pfSense | Alertes graduées par mail ; procédure d'escalade ; rapport d'incident ; mesures `iperf3` avant et après | VM MON (2 vCPU, 4 Go) ; relais de messagerie ; VM OPS pour GLPI (ticket automatique, option) |
| **N1 — Accès distant sécurisé** | Comparaison WireGuard et OpenVPN ; cadre juridique (transfert hors UE, perte d'un poste) ; impact sur le filtrage | VPN sur pfSense ; bastion Guacamole ; profils créés par script | Journal des échecs et blocage ; révocation d'un accès ; connexion depuis un smartphone | Client VPN sur smartphone ; VM OPS ; second réseau pour l'extension |
| **N2 — Segmentation et filtrage** | Matrice des flux avant et après ; analyse d'impact ; plan de retour arrière | Règles par alias ; zone Visiteurs ; Suricata sur pfSense | Journaux du pare-feu ; alerte sur un balayage de ports ; capture Wireshark expliquée | `nmap` ; paquet Suricata |

**Les trois familles sont-elles couvertes ?** Oui pour les quatre missions. N3 est la plus forte en conception et en continuité (sous-compétences 1 à 13) ; elle ne couvre qu'en partie 14 (automatiser), 15 (indicateurs) et 17 (amélioration). N4 comble précisément ces trois-là, plus 16 (incident).

**Couverture des 17 sous-compétences avec N3 puis N4**

| # | Sous-compétence | N3 (R1) | N4 (R2) |
|---|---|---|---|
| 1 | Besoin et cadre juridique | ✔ | ✔ |
| 2 | Impact d'une évolution | ✔ | |
| 3 | Dossier de choix | ✔ | ✔ |
| 4 | Qualité et disponibilité | ✔ | ✔ |
| 5 | Maquetter | ✔ | |
| 6 | Préparer les tests | ✔ | ✔ |
| 7 | Installer et configurer | ✔ | ✔ |
| 8 | Continuité | ✔ | |
| 9 | Qualité de service | ✔ | ✔ |
| 10 | Documentation | ✔ | ✔ |
| 11 | Intégration et acceptation | ✔ | |
| 12 | Déployer | ✔ | |
| 13 | Administrer à distance | ✔ | |
| 14 | Automatiser | en partie | ✔ |
| 15 | Indicateurs et journaux | en partie | ✔ |
| 16 | Incident | ✔ | ✔ |
| 17 | Maintenir et améliorer | en partie | ✔ |
