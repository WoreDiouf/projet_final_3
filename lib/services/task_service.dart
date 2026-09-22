import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create
  Future<void> createTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.tid).set(task.toMap());
  }

  // 2. Read (Stream global pour le Dashboard) Écouter toutes les tâches d'équipe en temps réel (pour le Dashboard)
  Stream<List<TaskModel>> getAllTasksStream() {
    return _db
        .collection('tasks')
        .orderBy('dateLimite', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    });
  }

  // 3. Modifier le statut d'une tâche (cochée / décochée)
  Future<void> updateTaskStatus(String tid, bool isDone) async {
    await _db.collection('tasks').doc(tid).update({'isDone': isDone});
  }

  // 4. Update Content (Modifier l'intitulé et la description de la tâche)
  Future<void> updateTaskContent(String tid, String nouveauTitre, String nouvelleDescription) async {
    await _db.collection('tasks').doc(tid).update({
      'titre': nouveauTitre,
      'description': nouvelleDescription,
    });
  }

   // 💡 SUPPRESSION LOGIQUE : Bascule le statut à 'annule' pour l'historique NoSQL
  Future<void> softDeleteTask(String tid) async {
    await _db.collection('tasks').doc(tid).update({
      'statut': 'annule',
      'isDone': false, // Assure la cohérence des filtres de l'anneau
    });
  }

  // 🚨 SUPPRESSION PHYSIQUE : Détruit définitivement le document de la base
  Future<void> hardDeleteTask(String tid) async {
    await _db.collection('tasks').doc(tid).delete();
  }
}