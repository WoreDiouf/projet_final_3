# 📱 TeamFlow - Système Mobile de Gestion de Projet Collaborative en Temps Réel

[![Flutter Version](https://shields.io)](https://flutter.dev)
[![Firebase](https://shields.io)](https://google.com)
[![Architecture](https://shields.io)](https://pub.dev)
[![OIF Certification](https://shields.io)](https://francophonie.org)
[![Grade](https://shields.io)](#)

**TeamFlow** est une plateforme mobile d'ingénierie collaborative de niveau avancé conçue pour centraliser, ordonnancer et piloter des flux de livrables au sein d'équipes décentralisées. En associant la puissance graphique réactive de **Flutter** à l'écosystème orienté documents de **Cloud Firestore**, l'application bannit l'usage des rafraîchissements manuels en implémentant des pipelines asynchrones bidirectionnels. 

L'application intègre des cinématiques matérielles poussées (Caméra/Galerie), une étanchéité sémantique stricte par e-mail, une file d'attente prioritaire par échéance et une architecture de persistance tolérante aux pannes.

---

## 🎨 1. Charte Graphique & Précision Ergonomique

L'identité visuelle de TeamFlow applique les concepts du *Flat Design Premium* pour structurer l'importance des données et éliminer la surcharge cognitive :

*   🌐 **Le Dégradé Linéaire Directeur (`#055062` ↔ `#0691B4`)** : Établit l'univers institutionnel, symbolise la stabilité et propulse les Call To Action (CTA).
*   🔷 **Bleu Soft (`#4A65D2`)** : Marqueur sémantique officiel du statut **En cours**, invitant à la concentration sur la tâche active.
*   🟢 **Vert Émeraude (`#3EC70B`)** : Dédié aux validations positives, aux cases à cocher de réussite et au traceur vectoriel circulaire.
*   🔴 **Rouge Alerte (`#FF4D4D`)** : Dédié au marquage visuel exclusif des éléments mis au rebut, assurant l'historique sans polluer l'espace de travail.
*   📐 **Composants** : Conteneurs de type `Card` de couleur blanche (`#FFFFFF`) pourvus d'un rayon de courbure de **16 à 24 pixels** pour un relief moderne et une zone d'interaction tactile optimisée.

---

## 🏗️ 2. Architecture Logicielle & Flux de Données

Le projet rejette les structures monolithiques et s'appuie sur une **Clean Architecture** segmentée en trois couches imperméables, garantissant un couplage faible et une haute testabilité (MVVM/MVC) :

```text
+-------------------------------------------------------+

|          COUCHE DE PRÉSENTATION : VUES (UI)           |
|  - Écrans d'écoute réactifs (StreamBuilder, Widgets)  |
+-------------------------------------------------------+
                           ▲
                           | Écoute et Notifie (ChangeNotifier)
                           ▼
+-------------------------------------------------------+

|      COUCHE DE GESTION D'ÉTAT : PROVIDERS (MÉTIER)    |
|  - Centralisation de l'état asynchrone (TaskProvider) |
+-------------------------------------------------------+
                           ▲
                           | Transfert de Modèles typés (toMap / fromMap)
                           ▼
+-------------------------------------------------------+

|      COUCHE D'ACCÈS AUX DONNÉES : SERVICES NoSQL      |
|  - Requêtes Firebase d'arrière-plan (Auth, Firestore) |
+-------------------------------------------------------+
```

### Le Rôle des Triggers de Synchronisation
*   **`ChangeNotifier` & `Provider`** : Pilotent le cycle de vie des états, capturent les exceptions d'arrière-plan et notifient chirurgicalement uniquement les widgets abonnés (ex: mise à jour des cadres statistiques), épargnant les ressources matérielles du processeur mobile.
*   **`StreamBuilder` (Permanent WebSockets)** : Établit un canal d'écoute persistant avec Cloud Firestore. Toute altération atomique des documents en base est immédiatement poussée vers l'interface utilisateur, forçant le rafraîchissement au pixel près sans aucune action manuelle.

---

## 🗃️ 3. Modélisation NoSQL (Cloud Firestore)

La persistance repose sur une modélisation orientée documents dénormalisée, optimisée pour les performances de lecture asynchrones.

### 👥 Collection `users`
Documents indexés par l'UID unique de Firebase Auth.
*   `uid` : `String` (Clé primaire immuable).
*   `nom` : `String` (Pseudonyme forcé en minuscules strictes à l'inscription).
*   `fullName` : `String` (Identité civile du collaborateur).
*   `email` : `String` (Pivot d'assignation et de sécurité).
*   `photoUrl` : `String` (Chemin d'accès absolu du fichier image local ou distant).

### 📂 Collection `projects`
Espaces collaboratifs parents.
*   `pid` : `String` (Identifiant unique généré).
*   `titre` / `description` : `String`.
*   `createurId` : `String` (UID du créateur).
*   `membres` : `List<String>` (Tableau stockant les e-mails des utilisateurs invités, servant de barrière d'étanchéité NoSQL).

### 📋 Collection `tasks`
Livrables unitaires rattachés.
*   `tid` : `String` (Identifiant de tâche).
*   `projectId` : `String` (Clé de liaison rattachée au projet parent).
*   `titre` / `description` : `String`.
*   `dateLimite` : `Timestamp` (Échéance chronologique).
*   `assigneA` : `String` (E-mail du responsable d'équipe).
*   `isDone` : `bool` (Drapeau binaire de validation).
*   `statut` : `String` (`'enCours'`, `'termine'`, `'annule'`).

---

## 🧠 4. Algorithmes Avancés Implémentés

### 4.1 Authentification Hybride Sécurisée (`AuthService`)
Permet une connexion transparente via e-mail ou pseudonyme. Le système nettoie les espaces parasites (`.trim()`) et interroge Firestore en minuscules si aucun caractère `@` n'est détecté pour résoudre l'e-mail correspondant.
```dart
Future<UserCredential> signInWithEmailOrUsername(String emailOrUsername, String password) async {
  String finalEmail = emailOrUsername.trim();

  if (!finalEmail.contains('@')) {
    final String cleanedUsername = finalEmail.toLowerCase();
    final querySnapshot = await _db
        .collection('users')
        .where('nom', isEqualTo: cleanedUsername)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw FirebaseAuthException(code: 'user-not-found', message: "Ce pseudonyme n'existe pas.");
    }
    finalEmail = querySnapshot.docs.first.data()['email'] ?? '';
  }
  return await _auth.signInWithEmailAndPassword(email: finalEmail, password: password);
}
```

### 4.2 File d'Attente Dynamique Chronologique (`Queue Pipeline`)
Pour éviter le découragement de l'utilisateur face à une accumulation de jalons, le Dashboard trie dynamiquement les tâches actives par ordre chronologique. La tâche dont l'échéance est la plus proche est isolée dans le cadre **EN COURS**, tandis que l'intégralité des tâches restantes est basculée dans le pipeline de mise en attente **TRAITEMENT**. Dès que la tâche prioritaire est cochée ou annulée, la tâche suivante de la file d'attente est automatiquement aspirée et promue en tête.

### 4.3 Algorithme d'Exclusion pour l'Anneau Vectoriel (`ProgressRing`)
L'anneau de progression de l'Écran 5 calcule l'avancement réel de l'équipe. Il est programmé pour filtrer localement et exclure mathématiquement les tâches annulées, évitant ainsi de pénaliser le ratio de réussite global du projet. Si un projet ne contient aucune tâche active, le système intercepte la division par zéro et recalcule l'anneau à `0%` (ou `100%` si toutes les tâches passées sont finalisées).

### 4.4 Circuit de Suppression Logique (*Soft Delete*)
Lorsqu'un collaborateur retire une tâche, le système rejette la destruction physique immédiate du document en base afin de préserver l'intégrité des statistiques. L'action transite par le Service pour faire muter le champ `statut` à `'annule'`. La tâche migre instantanément vers l'historique **ANNULÉ**, où sa case à cocher (Checkbox) est matériellement désactivée (`onChanged: null`) pour interdire toute altération ultérieure des données. Le document ne peut être détruit physiquement (*Hard Delete*) que par une action explicite à l'intérieur de la corbeille.

---

## 🎛️ 5. Routage Avancé : `MainNavigationScreen`

Pour répondre aux critères d'ergonomie modernes, l'application orchestre ses vues à l'aide d'un composant pivot doté d'une **`BottomNavigationBar`** fixe. L'arborescence utilise le widget **`IndexedStack`** de Flutter. Contrairement à un remplacement d'écran classique, l'IndexedStack maintient les instances des écrans vivantes en mémoire cache, évitant de fermer et de réouvrir les WebSockets Firebase lors des transitions et garantissant une navigation instantanée à zéro latence.

---

## 🧪 6. Pyramide des Tests (Fiabilité du Code)

L'assurance qualité logicielle est assurée par des suites de tests automatisées exécutables en ligne de commande :

### 6.1 Test Unitaire Modèle (`test/project_model_test.dart`)
Garantit la robustesse du constructeur `fromMap()` lors de la conversion des types bruts de Firestore (`List<dynamic>`) en types fortement typés de Dart (`List<String>`), tout en injectant des valeurs de secours en cas de champs nuls ou manquants.
```bash
flutter test test/project_model_test.dart
```

### 6.2 Test de Widget Composant (`test/progress_ring_test.dart`)
Valide unitairement le comportement graphique et mathématique du `CustomPainter` de l'anneau de progression face aux valeurs extrêmes ou arrondies.
```bash
flutter test test/progress_ring_test.dart
```

---

## 📦 7. Déploiement

### Prérequis CLI
```bash
# Restauration des packages Dart et Flutter
flutter pub get

# Lancement de l'application en environnement simulé
flutter run
```

---

### 🏁 un chef-d'œuvre officiellement Développé par Woré Diouf!

sous le tutorat de Bounyamine Baparape - Programme Professionnalisant D-CLIC / Organisation Internationale de la Francophonie (2026).
