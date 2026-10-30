# Mes pistes de missions — Quentin

**Épreuve :** E6 SISR (BTS SIO) · **Date :** 29 octobre 2026 (rendu de S2, rédigé en S3) · Matrice : [S02-matrice-missions](S02-matrice-missions.md)

## Piste 1 : N3 — Haute disponibilité de l'application de suivi des visites

- **Besoin de GSB :** l'application de suivi des visites doit rester accessible aux 480 visiteurs quand un serveur tombe, sans perte de données validées.
- **Ce que je livrerais :** HTTPS sur le répartiteur ; bascules du web et de la base testées et chronométrées ; plan de continuité (objectifs de reprise, procédures, tableau des pannes) ; seconde instance HAProxy avec keepalived en extension.
- **Pourquoi cette piste :** la chaîne HAProxy, Apache et Galera tourne déjà dans mon labo : je peux me concentrer sur la preuve et sur l'évolution. Elle couvre les trois familles de compétences. Elle se prête aux évolutions demandées en 1 h à l'épreuve : ajouter un serveur web, changer l'algorithme de répartition, activer l'affinité de session, ajouter HTTPS.
- **Risques ou points durs :** démarrage à froid de Galera (VM éteintes entre les séances) ; keepalived prévu tard dans ma feuille de route (à avancer) ; HTTPS derrière des ports non standard ; ressources partagées du cluster.

## Piste 2 : N4 — Supervision et qualité de service

- **Besoin de GSB :** voir les pannes avant les utilisateurs et protéger les services essentiels quand le réseau est chargé.
- **Ce que je livrerais :** contrat de service et indicateurs ; supervision d'au moins six éléments (pfSense, deux Linux, ADPSQS, web, DNS, base) ; alertes par mail à plusieurs niveaux ; déploiement des agents par script ou Ansible ; rapport d'incident ; en extension, limitation de débit mesurée sur pfSense.
- **Pourquoi cette piste :** elle comble ce que N3 laisse en partie (automatiser, indicateurs, amélioration) et la ligne 18 de l'annexe II.E, absente aujourd'hui. Elle prolonge naturellement R1 : alerte quand un serveur de la chaîne tombe. Elle correspond au projet Sentinelle de mon DAT.
- **Risques ou points durs :** ressources de la VM MON ; envoi de mail depuis le labo (relais à trouver) ; seuils réglés sans fausses alertes ; zone Visiteurs à créer pour l'extension.

## Piste 3 : N1 — Accès distant et interconnexion sécurisés

- **Besoin de GSB :** connecter les visiteurs depuis l'extérieur et administrer les serveurs sans exposer leur accès.
- **Ce que je livrerais :** VPN des visiteurs sur pfSense, limité à l'application ; script de création et de révocation des accès ; bastion avec journal ; test depuis un smartphone.
- **Pourquoi cette piste :** couvre la ligne 8 (terminal mobile) et, en extension, la ligne 23 de l'annexe II.E.
- **Risques ou points durs :** « l'extérieur » n'est que le réseau de l'école ; recouvre le bastion déjà prévu dans Sentinelle.

## Mon classement provisoire

1. **N3** pour la réalisation 1 : socle et extension (lot 3).
2. **N4** pour la réalisation 2 : socle, extension selon le temps restant.
3. **N1** en réserve.

Les autres briques de Sentinelle (Wazuh, Suricata, bastion, Nextcloud, GLPI) complètent l'**environnement** exigé par l'annexe II.E ; elles n'entrent pas dans le périmètre de R2, qui reste « le socle, ou le socle réduit ». Choix à valider avec le formateur avant S4.
