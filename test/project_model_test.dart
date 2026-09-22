import 'package:flutter_test/flutter_test.dart';
import 'package:projet_final_3/models/project_model.dart';

void main() {
  group('🧪 Tests Unitaires - Modèle de Données ProjectModel (TeamFlow)', () {
    
    test('Validation 1 : La sérialisation toMap() doit convertir l\'objet en dictionnaire JSON typé', () {
      // 🧱 1. Initialisation d'une instance propre du modèle projet
      final project = ProjectModel(
        pid: 'A6OJUoN3JfEj9QsdVqrc',
        titre: 'Refonte TeamFlow',
        description: 'Déploiement Flutter de niveau approfondi.',
        createurId: 'uid_dioufy_2026',
        membres: ['mamanfa8@gmail.com', 'cheikhouna17@gmail.com'],
      );

      // 🚀 2. Déclenchement de la méthode de sérialisation NoSQL
      final Map<String, dynamic> result = project.toMap();

      // 🔬 3. Assertions : Vérification de la conformité du dictionnaire produit
      expect(result['pid'], 'A6OJUoN3JfEj9QsdVqrc');
      expect(result['titre'], 'Refonte TeamFlow');
      expect(result['createurId'], 'uid_dioufy_2026');
      expect(result['membres'], isA<List<String>>());
      expect(result['membres'].length, 2);
    });

    test('Validation 2 : Le constructeur factory fromMap() doit décoder les tableaux dynamiques Firestore sans crash', () {
      // 🧱 1. Simulation d'un dictionnaire brut (JSON) renvoyé par un flux Cloud Firestore
      final Map<String, dynamic> mockFirestoreData = {
        'pid': 'A6OJUoN3JfEj9QsdVqrc',
        'titre': 'Refonte TeamFlow',
        'description': 'Déploiement Flutter de niveau approfondi.',
        'createurId': 'uid_dioufy_2026',
        // Firestore renvoie souvent les tableaux sous le type brut List<dynamic>
        'membres': ['mamanfa8@gmail.com', 'cheikhouna17@gmail.com'], 
      };

      // 🚀 2. Déclenchement du constructeur de désérialisation sécurisé que nous avons écrit
      final project = ProjectModel.fromMap(mockFirestoreData);

      // 🔬 3. Assertions : On valide que l'objet extrait est fortement et correctement typé
      expect(project.pid, 'A6OJUoN3JfEj9QsdVqrc');
      expect(project.titre, 'Refonte TeamFlow');
      expect(project.membres, isA<List<String>>()); // Vérifie que la liste dynamic a bien été convertie en List<String>
      expect(project.membres.contains('mamanfa8@gmail.com'), true);
    });

    test('Validation 3 : Le constructeur fromMap() doit injecter des valeurs par défaut en cas d\'attributs NoSQL manquants', () {
      // 🧱 1. Simulation d'un document Firestore corrompu ou incomplet (champs manquants)
      final Map<String, dynamic> incompleteFirestoreData = {
        'pid': 'A6OJUoN3JfEj9QsdVqrc',
        // 'titre', 'description' et 'membres' sont absents du dictionnaire
      };

      // 🚀 2. Déclenchement de la désérialisation avec tolérance aux pannes (opérateurs ??)
      final project = ProjectModel.fromMap(incompleteFirestoreData);

      // 🔬 3. Assertions : On vérifie que les filets de sécurité évitent le plantage de l'application
      expect(project.pid, 'A6OJUoN3JfEj9QsdVqrc');
      expect(project.titre, ''); // Doit renvoyer une chaîne vide par défaut au lieu de planter sur un Null
      expect(project.membres, isA<List<String>>());
      expect(project.membres.isEmpty, true); // La liste doit être initialisée à vide et non Null
    });
  });
}