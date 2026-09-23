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

  Future<void> toggleTaskStatus(String tid, bool currentStatus, String userEmail) async {
    try {
      bool newIsDone = !currentStatus;
      String nouveauStatut = newIsDone ? 'termine' : 'enCours';

      // 1. Mise à jour de la tâche cliquée
      await FirebaseFirestore.instance.collection('tasks').doc(tid).update({
        'isDone': newIsDone,
        'statut': nouveauStatut,
      });

      // 🚀 2. RECRUTEMENT AUTOMATIQUE DU FLUX DE TRAVAIL
      if (newIsDone) {
        // L'utilisateur vient de libérer sa place "en cours", on cherche la tâche en attente la plus proche
        final traitementSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('assigneA', isEqualTo: userEmail)
            .where('statut', isEqualTo: 'traitement')
            .get();

        if (traitementSnapshot.docs.isNotEmpty) {
          // Algorithme de tri par date limite la plus proche
          var docs = traitementSnapshot.docs;
          DocumentSnapshot plusUrgente = docs.first;

          for (var doc in docs) {
            DateTime currentLimit = (doc.get('dateLimite') as Timestamp).toDate();
            DateTime lowestLimit = (plusUrgente.get('dateLimite') as Timestamp).toDate();
            if (currentLimit.isBefore(lowestLimit)) {
              plusUrgente = doc;
            }
          }

          // La tâche en traitement la plus urgente est promue "en cours" !
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(plusUrgente.id)
              .update({'statut': 'enCours'});
        }
      }
    } catch (e) {
      debugPrint("Erreur flux de traitement : $e");
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
