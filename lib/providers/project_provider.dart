import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final _projectService = ProjectService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Action : Create
  Future<bool> addProject({
    required String titre,
    required String description,
    required String createurId,
    required List<String> membres,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Affiche le chargement sur le bouton

    try {
      // Génération automatique d'un UID unique pour le document NoSQL
      String pid = FirebaseFirestore.instance.collection('projects').doc().id;

      // Construction de l'instance du modèle
      ProjectModel newProject = ProjectModel(
        pid: pid,
        titre: titre,
        description: description,
        createurId: createurId,
        membres: membres,
      );

      // Envoi à Firestore via le service
      await _projectService.createProject(newProject);

      _isLoading = false;
      notifyListeners();
      return true; // Succès
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Échec
    }
  }

   // ACTION : Update (Modifier un projet)
  Future<bool> editProject({
    required String pid,
    required String titre,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _projectService.updateProject(pid, titre, description);
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

  //  ACTION : Delete (Supprimer un projet)
  Future<bool> removeProject(String pid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _projectService.deleteProject(pid);
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
