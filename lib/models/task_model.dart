import 'package:cloud_firestore/cloud_firestore.dart';
enum StatutTask {
  enCours,
  traitement,
  termine,
  annule
}

class TaskModel {
  final String tid;
  final String titre;
  final String description;
  final DateTime dateLimite;
  final String projectId;
  final String assigneA;
  final bool isDone;
  final StatutTask statut; 

  TaskModel({
    required this.tid,
    required this.titre,
    required this.description,
    required this.dateLimite,
    required this.projectId,
    required this.assigneA,
    required this.isDone,
    this.statut = StatutTask.enCours, // Par défaut, une nouvelle tâche est "En cours"
  });

  Map<String, dynamic> toMap() {
    return {
      'tid': tid,
      'titre': titre,
      'description': description,
      'dateLimite': Timestamp.fromDate(dateLimite),
      'projectId': projectId,
      'assigneA': assigneA,
      'isDone': isDone,
      'statut': statut.name, 
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final statutStr = map['statut'] ?? 'enCours';
    final statutEnum = StatutTask.values.firstWhere(
      (e) => e.name == statutStr,
      orElse: () => StatutTask.enCours,
    );

    return TaskModel(
      tid: map['tid'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      dateLimite: (map['dateLimite'] as Timestamp).toDate(),
      projectId: map['projectId'] ?? '',
      assigneA: map['assigneA'] ?? '',
      isDone: map['isDone'] ?? false,
      statut: statutEnum,
    );
  }
}