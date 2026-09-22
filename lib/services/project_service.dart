import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Ajouter un nouveau projet dans la collection 'projects'
  Future<void> createProject(ProjectModel project) async {
    await _db.collection('projects').doc(project.pid).set(project.toMap());
  }

  // 2. Read (Stream) :Écouter les projets en temps réel où l'utilisateur connecté est membre
  Stream<List<ProjectModel>> getProjectsStream(String userId) {
    return _db
        .collection('projects')
        .where('membres', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    });
  }

  // 3. Update (Modifier le titre et la description)
  Future<void> updateProject(String pid, String nouveauTitre, String nouvelleDescription) async {
    await _db.collection('projects').doc(pid).update({
      'titre': nouveauTitre,
      'description': nouvelleDescription,
    });
  }

  // 4. Delete (Supprimer définitivement le projet NoSQL)
  Future<void> deleteProject(String pid) async {
    await _db.collection('projects').doc(pid).delete();
  }
}