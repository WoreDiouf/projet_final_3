import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../models/task_model.dart';
import '../widgets/progress_ring.dart';
import 'add_task_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectTitle;
  final String pid; // Identifiant unique du projet cliqué

  const ProjectDetailsScreen({
    super.key, 
    required this.projectTitle, 
    required this.pid,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    // 👤 Récupération de l'email de l'utilisateur connecté pour le filtrage NoSQL strict
    final currentUser = FirebaseAuth.instance.currentUser;
    final String userEmail = currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.projectTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gradientTop),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 📊 SECTION 1 : ANNEAU DE PROGRESSION DYNAMIQUE FILTRÉ SUR L'UTILISATEUR CONNECTÉ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('projectId', isEqualTo: widget.pid)
                    .where('assigneA', isEqualTo: userEmail)
                    .snapshots(),
                builder: (context, taskSnapshot) {
                  double dynamicPercentage = 0.0;
                  int totalTasks = 0;
                  int completedTasks = 0;

                  if (taskSnapshot.hasData && taskSnapshot.data!.docs.isNotEmpty) {
                    final docs = taskSnapshot.data!.docs;

                    // 🧠 FILTRE ALGORITHMIQUE UNIQUE : On ignore les tâches annulées
                    final activeTasks = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['statut'] != 'annule'; // N'accepte que les tâches valides du flux
                    }).toList();

                    totalTasks = activeTasks.length;
                    
                    completedTasks = activeTasks.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['isDone'] == true || data['statut'] == 'termine');
                    }).length;

                    if (totalTasks > 0) {
                      dynamicPercentage = (completedTasks / totalTasks) * 100;
                    } else {
                      dynamicPercentage = 100.0; // 💡 Si toutes les tâches restantes sont finies (ou s'il n'y a plus que des annulées), la progression remonte à 100% !
                    }
                  }

                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          ProgressRing(
                            percentage: dynamicPercentage,
                            size: 85.0,
                            strokeWidth: 9.0,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progression Globale',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalTasks == 0 
                                      ? 'Toutes les tâches en cours de ce projet ont été complétées ou annulées.'
                                      : 'Suivi personnel : $completedTasks/$totalTasks de mes tâches validées.',
                                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.55), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // ➕ SECTION 2 : BARRE D'ACTION (Titre + Bouton Ajouter Tâche)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tâches du projet",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTaskScreen(projectPid: widget.pid)),
                      );
                    },
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.gradientTop, size: 20),
                    label: const Text(
                      "AJOUTER",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gradientTop, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 📋 SECTION 3 : LISTE DES TÂCHES FILTRÉE (PROJET + UTILISATEUR CONNECTÉ)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('projectId', isEqualTo: widget.pid)
                    .where('assigneA', isEqualTo: userEmail)
                    // 💡 On retire le "isNotEqualTo" pour que la tâche reste visible à l'écran !
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text(
                          "Vous n'avez aucune tâche assignée dans ce projet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
                        ),
                      ),
                    );
                  }

                  final taskDocs = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taskDocs.length,
                    itemBuilder: (context, index) {
                      final data = taskDocs[index].data() as Map<String, dynamic>;
                      final task = TaskModel.fromMap(data);
                      
                      // 🔬 Détection du statut d'annulation NoSQL
                      bool isAnnullee = data['statut'] == 'annule';

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.titre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 15, 
                                        // Si annulée, on grise légèrement le texte par élégance, ou on barre si terminée
                                        color: isAnnullee ? Colors.black45 : Colors.black87,
                                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAnnullee ? "Statut : Mise au rebut" : "Responsable : Moi (${task.assigneA})",
                                      style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 🎨 CONFIGURATION DES BADGES DYNAMIQUES (Vert / Bleu / Rouge Annulé)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isAnnullee
                                      ? Colors.redAccent.withOpacity(0.12) // 🔴 Fond rouge translucide
                                      : (task.isDone 
                                          ? AppColors.accentStatus.withOpacity(0.12)
                                          : const Color(0xFF4A65D2).withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isAnnullee 
                                      ? "Annulé" // 🔴 Libellé Annulé
                                      : (task.isDone ? "Terminé" : "En cours"),
                                  style: TextStyle(
                                    color: isAnnullee 
                                        ? Colors.redAccent // 🔴 Texte rouge vif
                                        : (task.isDone ? AppColors.accentStatus : const Color(0xFF4A65D2)), 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}