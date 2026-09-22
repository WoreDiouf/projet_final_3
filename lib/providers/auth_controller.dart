import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _error;

  // Encapsulation sécurisée des variables d'état (Getters)
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Action de connexion hybride 
  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Appel du service intelligent
      await _authService.signInWithEmailOrUsername(emailOrUsername, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Capture les erreurs Firestore ou les erreurs de mot de passe Firebase Auth
      if (e is FirebaseAuthException) {
        _error = e.message;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Action d'inscription 
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String fullName,
    File? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        nom: nom,
        fullName: fullName,
        imageFile: imageFile,
      );
      _isLoading = false;
      notifyListeners();
      return true; // Inscription et stockage Firestore réussis
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Échec de l'inscription
    }
  }

  // ACTION : Déconnexion réactive
  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  // ACTION : Modification du profil utilisateur (Update)
  Future<bool> updateProfile({
    required String uid,
    required String fullName,
    required String nom,
    required String photoUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.updateUserProfile(
        uid: uid,
        newFullName: fullName,
        newNom: nom,
        newPhotoUrl: photoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
