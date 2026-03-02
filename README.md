# Projet VoIP - Déploiement et Sécurisation d'une Infrastructure Asterisk
---
Dans votre environnement professionnel futur, vous allez peut-être être
amenés à désigner, mettre en place, administrer ou maintenir une
architecture VoIP (Voice over IP).

Il est donc nécessaire de commencer tout de suite à faire une veille
technologique sur la VoIP et à en relever les avantages, inconvénients,
chercher les solutions existantes sur le marché, qu’elles soient intégrées, clef
en main ou customisées, sur mesure...

## 2. Présentation fonctionnelle
L'architecture repose sur un IP-PBX **Asterisk** (version 23) déployé sur un environnement Debian.Le choix d'implémenter le canal moderne **PJSIP** (au lieu de l'obsolète `chan_sip`) pour garantir une meilleure gestion des terminaux (Endpoints) et de la sécurité.

**Fonctionnalités déployées :**
* **Routage de base :** Appels internes fonctionnels entre utilisateurs (via softphones PortSIP UC / Linphone).
* **Sécurité cryptographique :** Implémentation stricte du chiffrement. La signalisation (SIP) est protégée par un tunnel **TLS** (port 5061), et le flux média (RTP) est chiffré via **SRTP** à l'aide de certificats générés sur le serveur.
* **Serveur Vocal Interactif (SVI) :** Mise en place d'un automate de routage (menu DTMF type "tapez 1, tapez 2").
* **Conditions horaires et Messagerie :** Routage dynamique (mode Ne pas déranger) en dehors des horaires d'ouverture (9h-18h), avec bascule vers des boîtes vocales protégées par code PIN.

## 3. Avantages et inconvénients
**Avantages de la solution :**
* **Optimisation des coûts :** Disparition de l'infrastructure de câblage dédiée à la téléphonie ; mutualisation sur le réseau data existant (LAN/WAN).
* **Flexibilité et Scalabilité :** L'ajout de nouveaux postes ou la modification du plan de numérotation se fait de manière logicielle, sans intervention physique.

**Inconvénients et Mitigations :**
* **Dépendance réseau (QoS) :** La VoIP est extrêmement sensible à la latence et à la gigue. Une perte du réseau IP entraîne une perte totale de la téléphonie.
* **Vulnérabilité native :** Par défaut, le protocole SIP transite en clair. **Mitigation appliquée :** Déploiement de certificats pour forcer le TLS/SRTP et empêcher le *sniffing* (écoute réseau).

## 4. Solutions existantes sur le marché
* **Solutions Open Source :** Asterisk (moteur PBX ultra-personnalisable), OpenSIPS/Kamailio (spécialisés dans le routage massif et la fonction SBC), FreePBX (surcouche graphique pour Asterisk).
* **Solutions Propriétaires :** 3CX, Cisco Unified Communications Manager, Microsoft Teams Phone.

## 5. Exemples d'implémentation
L'architecture VoIP s'adapte au besoin métier. 
Un **standard administratif classique** se contentera de groupes d'appels simples et de renvois sur non-réponse. À l'inverse, un **centre d'appels (Call Center)** nécessitera une implémentation complexe : files d'attente (Queues) avec algorithmes de distribution (Round Robin), enregistrement légal des flux audios, et couplage CTI (Computer Telephony Integration) pour remonter les fiches clients du CRM lors d'un appel entrant.

## 6. Choix Architecturaux et Gestion des Incidents
Ce projet a nécessité des prises de décision techniques face à des contraintes opérationnelles :

* **Incident LDAP et Continuité d'Activité :** L'intégration de l'annuaire LDAP du projet précédent était prévue. Le serveur maître s'étant avéré indisponible, j'ai développé un script Bash (`add_users.sh`) permettant d'ingérer un fichier CSV pour injecter dynamiquement les utilisateurs dans la configuration PJSIP. Ce PCA (Plan de Continuité d'Activité) garantit la mise en production malgré la défaillance d'un service tiers.
* **Interopérabilité SRTCP :** Lors des tests de chiffrement avec le client PortSIP UC, des erreurs `SRTCP unprotect failed` ont été remontées par Asterisk. L'analyse réseau a confirmé que seul le déchiffrement des paquets de statistiques (RTCP) était impacté par un paramètre non supporté par la bibliothèque `libsrtp`. Le flux vocal principal (SRTP) restant parfaitement négocié et chiffré, cette configuration a été validée et maintenue.

## 7. Plan de Test et Recette

| État initial | Fonctionnalité testée | Comportement attendu | Séquence de test | Commentaires | Résultat |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Serveur UP, terminaux 100 et 200 enregistrés | Connectivité et Chiffrement | L'appel aboutit. L'audio est bidirectionnel et chiffré. | 1. 100 appelle 200.<br>2. 200 décroche.<br>3. Test voix. |
| Serveur UP, horaire hors ouverture (ex: 20h) | Routage horaire (DnD) | L'appel est intercepté et envoyé directement sur la boîte vocale de la cible. | 1. Appeler le 100.<br>2. Écouter le message vocal. | Validation de la directive `GotoIfTime` dans le Dialplan. | **OK** |
| Serveur UP | Automate SVI | Le menu interactif décroche, lit l'audio, et route l'appel selon la touche pressée (DTMF). | 1. Appeler le numéro court (800).<br>2. Taper 1 ou 2. | Validation de la reconnaissance des inputs DTMF par le serveur. | **OK** |

## 8. Conclusion
La conception de cette infrastructure démontre que la véritable valeur ajoutée dans le déploiement de la VoIP ne réside pas dans la simple installation du moteur logiciel, mais dans la maîtrise approfondie du routage conditionnel (Dialplan) et des couches réseaux sous-jacentes. L'imposition du chiffrement TLS/SRTP, bien que complexe à orchestrer avec les clients terminaux, est aujourd'hui une norme non négociable pour garantir la confidentialité des communications d'entreprise.
