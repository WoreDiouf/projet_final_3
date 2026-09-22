import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/app_colors.dart';
import 'providers/auth_controller.dart';
import 'providers/project_provider.dart';
import 'providers/task_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'TeamFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        
        // 🚀 NAVIGATION INTELLIGENTE ET PERSISTANTE : Écoute l'état NoSQL de Firebase
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(), // Écoute la session en cache sur le PC/Téléphone
          builder: (context, snapshot) {
            // 1. Pendant le temps de communication initial avec les serveurs de Firebase
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.gradientTop),
                ),
              );
            }

            // 2. ⚡ L'utilisateur a déjà une session valide enregistrée -> Redirection directe au Dashboard !
            if (snapshot.hasData && snapshot.data != null) {
              return const DashboardScreen();
            }

            // 3. Aucune session trouvée (ou déconnecté) -> Direction l'Écran de Bienvenue de base
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}