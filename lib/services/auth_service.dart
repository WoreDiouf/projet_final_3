import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Écouteur en temps réel des changements d'état de la session (Connecté / Déconnecté)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //  Connexion hybride par E-mail OU par Nom d'utilisateur
  Future<UserCredential> signInWithEmailOrUsername(String emailOrUsername, String password) async {
    String finalEmail = emailOrUsername.trim();

    // 🔬 Détection : Si ce n'est pas un e-mail (absence de '@'), on cherche le pseudo dans Firestore
    if (!finalEmail.contains('@')) {
      // Nettoyage en minuscules pour correspondre à notre logique d'inscription sécurisée
      final String cleanedUsername = finalEmail.toLowerCase();

      final querySnapshot = await _db
          .collection('users')
          .where('nom', isEqualTo: cleanedUsername) // Cherche le champ pseudonyme exact
          .limit(1)
          .get();

      // Si le pseudo n'existe nulle part en base NoSQL
      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: "Ce nom d'utilisateur n'existe pas.",
        );
      }

      // Récupération transparente de l'e-mail lié au pseudo trouvé dans le document Firestore
      finalEmail = querySnapshot.docs.first.data()['email'] ?? '';
    }

    // Connexion officielle finale auprès de Firebase Auth avec l'e-mail résolu en tâche de fond
    return await _auth.signInWithEmailAndPassword(email: finalEmail, password: password);
  }

  // Fonction d'inscription asynchrone sécurisée avec vérification d'unicité du pseudo
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nom, 
    required String fullName,
    File? imageFile,
  }) async {
    // 🔍 1. Forcer le pseudo en minuscules et supprimer les espaces parasites
    final String cleanedUsername = nom.trim().toLowerCase();

    // 🔬 2. Vérification flash dans Firestore : est-ce que ce pseudo existe déjà ?
    final usernameCheck = await _db
        .collection('users')
        .where('nom', isEqualTo: cleanedUsername)
        .limit(1)
        .get();

    // Si le pseudo est trouvé, on lève une exception sur mesure pour bloquer l'inscription
    if (usernameCheck.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: "Ce nom d'utilisateur est déjà pris par un autre membre.",
      );
    }

    // 🚀 3. Si le pseudo est libre, création officielle dans Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    String finalPhotoPath = "";
    if (imageFile != null) {
      finalPhotoPath = imageFile.path; // 💡 Enregistre le vrai chemin (ex: /data/user/0/...) !
    }

    // 🧱 4. Construction de l'instance avec le pseudo nettoyé unique
    UserModel user = UserModel(
      uid: credential.user!.uid,
      nom: cleanedUsername, 
      fullName: fullName.trim(),
      email: email.trim(),
      photoUrl: finalPhotoPath,
    );

    // 📂 5. Enregistrement final dans le document NoSQL Firestore
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }
  
  // Déconnexion officielle de Firebase Auth
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mise à jour du profil de l'utilisateur connecté dans Firestore
  Future<void> updateUserProfile({
    required String uid,
    required String newFullName,
    required String newNom,
    required String newPhotoUrl,
  }) async {
    await _db.collection('users').doc(uid).update({
      'fullName': newFullName,
      'nom': newNom,
      'photoUrl': newPhotoUrl,
    });
  }
}
