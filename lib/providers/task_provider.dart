import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final _taskService = TaskService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Action : Create
  Future<bool> addTask({
    required String titre,
    required String description,
    required DateTime dateLimite,
    required String assigneA,
    required String projectId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Active le spinner de chargement sur le bouton

    try {
      // Génération automatique d'un UID unique pour le document de la tâche NoSQL
      String tid = FirebaseFirestore.instance.collection('tasks').doc().id;

      // Construction de l'instance de notre modèle
      TaskModel newTask = TaskModel(
        tid: tid,
        titre: titre,
        description: description,
        dateLimite: dateLimite,
        assigneA: assigneA,
        projectId: projectId,
        isDone: false, // Par défaut, une nouvelle tâche n'est pas cochée
        statut: StatutTask.enCours,
      );

      // Envoi à Firestore via le service dédié
      await _taskService.createTask(newTask);

      _isLoading = false;
      notifyListeners();
      return true; // Succès de l'opération
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Échec
    }
  }

  // Action : Toggle Checkbox Status rapide pour basculer l'état de la coche directement depuis l'UI
  Future<void> toggleTaskStatus(String tid, bool currentStatus) async {
    try {
      await _taskService.updateTaskStatus(tid, !currentStatus);
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour du statut : $e");
    }
  }

  // ACTION : Update Content (Modifier l'intitulé d'une tâche)
  Future<bool> editTaskContent({
    required String tid,
    required String titre,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.updateTaskContent(tid, titre, description);
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

  // Action réactive : Appel de la suppression logique du service
  Future<bool> removeTask(String tid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🚀 Appel officiel de la couche de service NoSQL
      await _taskService.softDeleteTask(tid);
      
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

  // Action réactive : Appel de la suppression physique définitive
  Future<bool> permanentlyDeleteTask(String tid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🚀 Appel officiel de la couche de service NoSQL
      await _taskService.hardDeleteTask(tid);
      
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
