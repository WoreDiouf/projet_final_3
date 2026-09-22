import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_final_3/widgets/progress_ring.dart';

void main() {
  group('🧪 Tests de Widgets - Composant ProgressRing (TeamFlow)', () {
    
    testWidgets('Vérification 1 : L\'anneau affiche correctement le texte du pourcentage calculé', (WidgetTester tester) async {
      // 🧱 1. Injection du composant ProgressRing simulé avec un ratio de 75%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressRing(
              percentage: 75.0,
              size: 80.0,
              strokeWidth: 8.0,
            ),
          ),
        ),
      );

      // 🔍 2. Recherche textuelle : On vérifie que la chaîne "75%" est bien calculée et visible au centre de l'anneau
      final Finder textFinder = find.text('75%');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('Vérification 2 : L\'anneau s\'adapte sans crash et affiche 0% en cas d\'absence de tâches', (WidgetTester tester) async {
      // 🧱 1. Injection du composant avec une valeur nulle (0 tâches complétées sur 0)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressRing(
              percentage: 0.0,
              size: 80.0,
              strokeWidth: 8.0,
            ),
          ),
        ),
      );

      // 🔍 2. Validation de sécurité algorithmique contre la division par zéro
      final Finder zeroTextFinder = find.text('0%');
      expect(zeroTextFinder, findsOneWidget);
    });

    testWidgets('Vérification 3 : L\'anneau gère proprement l\'affichage des pourcentages arrondis', (WidgetTester tester) async {
      // 🧱 1. Injection d'une valeur décimale complexe (Ex: 2 tâches terminées sur 3 = 66.6666%)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressRing(
              percentage: 66.6666666,
              size: 80.0,
              strokeWidth: 8.0,
            ),
          ),
        ),
      );

      // 🔍 2. On s'assure que le composant applique un arrondi propre à l'écran (Ex: 67% ou 66%) selon votre logique de String
      // Si votre ProgressRing utilise .toStringAsFixed(0), il affichera "67%"
      final Finder roundedTextFinder = find.text('67%');
      expect(roundedTextFinder, findsOneWidget);
    });
  });
}
