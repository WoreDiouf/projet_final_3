import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../models/task_model.dart';
import '../widgets/progress_ring.dart';
import 'add_task_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectTitle;
  final String pid; // L'ID unique du projet cliqué

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
    // 👤 Récupération de la session pour distinguer visuellement vos tâches de celles de vos collègues
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
        child: StreamBuilder<QuerySnapshot>(
          // 💡 DEVENU GLOBAL : On écoute TOUTES les tâches rattachées à ce projet en temps réel !
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('projectId', isEqualTo: widget.pid)
              .snapshots(),
          builder: (context, snapshot) {
            double dynamicPercentage = 0.0;
            int totalTasks = 0;
            int completedTasks = 0;
            List<DocumentSnapshot> activeTasks = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final docs = snapshot.data!.docs;

              // On ignore uniquement les fiches mises au rebut de l'historique d'annulation
              activeTasks = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['statut'] != 'annule';
              }).toList();

              totalTasks = activeTasks.length;
              
              completedTasks = activeTasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['isDone'] == true || data['statut'] == 'termine');
              }).length;

              if (totalTasks > 0) {
                dynamicPercentage = (completedTasks / totalTasks) * 100;
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 📊 SECTION 1 : ANNEAU DE PROGRESSION COLLECTIVE DE L'ÉQUIPE
                  Card(
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
                                // 💡 TEXTE CORRIGÉ : Devient un suivi d'équipe complet aligné sur l'anneau principal
                                Text(
                                  totalTasks == 0 
                                      ? 'Aucune tâche active planifiée pour ce projet.'
                                      : 'Suivi d\'équipe : $completedTasks/$totalTasks livrables à validés.',
                                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.55), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ➕ SECTION 2 : BARRE D'ACTION (Titre + Bouton Ajouter)
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

                  // 📋 SECTION 3 : LISTE DE TOUTES LES TÂCHES DU PROJET ET LEURS RESPONSABLES
                  if (activeTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text(
                          "Aucune tâche en cours dans ce projet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        final data = activeTasks[index].data() as Map<String, dynamic>;
                        final task = TaskModel.fromMap(data);
                        
                        bool estMaTache = task.assigneA == userEmail;

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
                                          color: Colors.black87,
                                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 💡 DYNAMIQUE : Affiche "Moi" ou l'adresse e-mail réelle du collaborateur en base !
                                      Text(
                                        estMaTache 
                                            ? "Responsable : Moi (Vous)" 
                                            : "Responsable : ${task.assigneA}",
                                        style: TextStyle(
                                          fontSize: 13, 
                                          color: estMaTache ? AppColors.gradientTop : Colors.black.withOpacity(0.5),
                                          fontWeight: estMaTache ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // LE BADGE D'ÉTAT DYNAMIQUE DU JALON
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: task.isDone? AppColors.accentStatus.withOpacity(0.12):
                                     const Color(0xFF4A65D2).withOpacity(0.12),borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    task.isDone ? "Terminé" : "En cours",
                                    style: TextStyle(
                                      color: task.isDone ? AppColors.accentStatus : const Color(0xFF4A65D2),
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
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }
