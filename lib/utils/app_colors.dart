import 'package:flutter/material.dart';

class AppColors {
  // 1. Les deux couleurs de base de votre dégradé linéaire Figma
  static const Color gradientTop = Color(0xFF055062);    // Bleu canard (0% - Opacité 100%)
  static const Color gradientBottom = Color(0xFF0691B4); // Bleu turquoise (100% - Opacité 80%)

  // 2. Le composant Dégradé Linéaire Réutilisable (Pour le fond ET pour les boutons)
  static const LinearGradient appLinearGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientTop,
      gradientBottom,
    ],
  );

  // 3. Éléments de surfaces et arrière-plans
  static const Color cardBackground = Colors.white;      // Fond propre des cartes blanches
  static const Color background = Color(0xFFF8F9FA);     // Gris très clair pour le Dashboard
  static const Color accentStatus = Color(0xFF3EC70B);   // Vert Émeraude (Coches / Jauges)

  // 4. Les 4 Cadres Statistiques de l'Écran 4
  static const Color cardOngoing = Color(0xFF4A65D2);    // Bleu Ongoing
  static const Color cardInProgress = Color(0xFF4CE3B2); // Vert En traitement
  static const Color cardCompleted = Color(0xFF4CBCE3);  // Turquoise Terminé
  static const Color cardCancel = Color(0xFF7952E5);     // Violet Annulé
}
