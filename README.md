# TAGO_PORTAIL 🚀

Gestionnaire de portail captif et système de génération de tickets Wi-Fi Zone pour routeurs **MikroTik RouterOS**, inspiré du mécanisme de fonctionnement de *Mikhmon v3/v7*, mais conçu pour s'exécuter de manière autonome, **sans aucun abonnement mensuel**.

## 📱 Présentation du Projet
**TAGO_PORTAIL** est une application mobile développée avec Flutter (v3.19.6). Elle s'appuie sur une infrastructure locale hébergée directement sur un appareil Android via **AWebServer**. L'application communique avec le serveur Web local pour exécuter des scripts PHP légers, qui interagissent ensuite avec l'API officielle de MikroTik pour administrer les utilisateurs du Hotspot.

### ✨ Caractéristiques principales
* **Zéro abonnement :** Totalement gratuit et autonome à vie.
* **Architecture Locale :** Hébergement PHP/MySQL ou SQLite en local via l'application **AWebServer**.
* **Impression thermique :** Intégration native du plugin `blue_thermal_printer` pour l'impression physique immédiate des tickets sur imprimante de poche (ESC/POS).
* **Sécurisé & Privé :** Aucune donnée de vente ou de ticket ne transite par un serveur tiers externe.
* **Calculations Hors-Ligne :** Gestion et suivi des profils de tickets (ex: 1h, 3h, illimité) en toute simplicité.

---

## 📂 Architecture Propre du Dépôt
Pour éviter tout conflit d'interprétation lors des builds automatisés (CI/CD) sur GitHub Actions, le projet respecte strictement la structure racine suivante :

```text
TAGO_PORTAIL/
├── .github/workflows/
│   └── build-apk.yml       # Workflow CI/CD de compilation automatique (Node 24 / Gradle 8.2)
├── android/                # Code natif Android (Configuration Gradle 8.2.1 & SDK 34)
├── lib/                    # Code source de l'application Flutter
│   └── main.dart           # Point d'entrée principal de l'application
├── pubspec.yaml            # Dépendances du projet (blue_thermal_printer, http)
└── README.md               # Documentation globale du projet
```

---

## 🛠️ Déploiement Local avec AWebServer
Pour faire fonctionner le mécanisme de requêtes `awebservice` sans serveur cloud distant :

1. Installez l'application **AWebServer** (disponible sur le Play Store) sur le téléphone Android faisant office de serveur local.
2. Déplacez vos scripts PHP d'interaction API MikroTik dans le répertoire Web public d'AWebServer (généralement `sdcard/AWebServer/www/`).
3. Notez l'adresse IP locale affichée par AWebServer (ex: `http://127.0.0.1:8080` ou l'adresse IP de votre réseau Wi-Fi local).
4. Renseignez cette URL cible dans les paramètres de connexion de l'interface de **TAGO_PORTAIL** pour lier l'application aux routeurs de votre zone.

---

## 🤖 Compilation Automatique (CI/CD)
Le fichier `.github/workflows/build-apk.yml` compile automatiquement une version de production de l'APK (mode Release) à chaque fois que vous envoyez (`git push`) une modification sur les branches `main` ou `master`.

L'APK finalisé est récupérable directement dans l'onglet **Actions** de ce dépôt de code sous la forme d'un artéfact téléchargeable nommé `tago-portail-apk`.

---
⚡ *Développé pour l'infrastructure réseau de Transport Burkinabè d'énergie.*
