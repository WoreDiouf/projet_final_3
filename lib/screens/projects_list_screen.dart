import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../models/project_model.dart';
import '../widgets/progress_ring.dart';
import 'project_details_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  // 0 = En cours (Projets avec tâches actives), 1 = All (Tous), 2 = Terminé (Projets à 100%)
  int _activeTab = 1; // On l'initialise sur "All" par défaut pour tout voir au démarrage

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String userEmail = currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mes Projets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gradientTop),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 🎛️ 1. BARRE D'ONGLETS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E6EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'En cours'),
                    _buildTabButton(1, 'All'),
                    _buildTabButton(2, 'Terminé'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📋 2. LISTE FLUIDE DES PROJETS D'ÉQUIPE NoSQL
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .where('membres', arrayContains: userEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun projet pour le moment.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45),
                      ),
                    );
                  }

                  final projectDocs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: projectDocs.length,
                    itemBuilder: (context, index) {
                      final data = projectDocs[index].data() as Map<String, dynamic>;
                      final project = ProjectModel.fromMap(data);

                      // 💡 COHÉRENCE : On écoute TOUTES les tâches liées à ce projet pour avoir la vraie progression d'équipe !
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tasks')
                            .where('projectId', isEqualTo: project.pid)
                            .where('assigneA', isEqualTo: userEmail)
                            .snapshots(),
                        builder: (context, taskSnapshot) {
                          double percentage = 0.0;
                          int totalTasks = 0;
                          int completedTasks = 0;
                          List<DocumentSnapshot> listeDesTasksDuProjet = [];

                          if (taskSnapshot.hasData) {
                            final docs = taskSnapshot.data!.docs;
                            
                            // 🧠 LOGIQUE EXCLUSIVE : On exclut les tâches annulées du décompte général !
                            listeDesTasksDuProjet = docs.where((d) {
                              final tData = d.data() as Map<String, dynamic>;
                              return tData['statut'] != 'annule';
                            }).toList();

                            totalTasks = listeDesTasksDuProjet.length;
                            
                            completedTasks = listeDesTasksDuProjet.where((d) {
                              final tData = d.data() as Map<String, dynamic>;
                              return tData['isDone'] == true || tData['statut'] == 'termine';
                            }).length;
                            
                            if (totalTasks > 0) {
                              percentage = (completedTasks / totalTasks) * 100;
                            } else {
                              percentage = 100.0; // Si plus de tâches actives, la progression remonte à 100%
                            }
                          }

                          // 🎛️ FILTRAGE DES ONGLETS
                          bool afficherLaCarte = false;
                          if (_activeTab == 1) {
                            afficherLaCarte = true;
                          } else if (_activeTab == 0 && (percentage < 100.0 || totalTasks == 0)) {
                            afficherLaCarte = true;
                          } else if (_activeTab == 2 && percentage == 100.0 && totalTasks > 0) {
                            afficherLaCarte = true;
                          }

                          if (!afficherLaCarte) return const SizedBox.shrink();

                          return _buildProjectCardItem(project, totalTasks, percentage, listeDesTasksDuProjet);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    bool isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSelected ? AppColors.gradientTop : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCardItem(ProjectModel project, int totalTasks, double percentage, List<DocumentSnapshot> projectTasks) {
    
    // 📅 Algorithme d'extraction de l'échéance : On cherche la date limite la plus proche parmi les tâches du projet
    String echeanceTexte = "Pas d'échéance";
    if (projectTasks.isNotEmpty) {
      try {
        // On trie les tâches locales pour trouver la date limite la plus proche
        DateTime plusProche = (projectTasks.first.data() as Map<String, dynamic>)['dateLimite'] != null
            ? ((projectTasks.first.data() as Map<String, dynamic>)['dateLimite'] as Timestamp).toDate()
            : DateTime.now();

        for (var doc in projectTasks) {
          final tData = doc.data() as Map<String, dynamic>;
          if (tData['dateLimite'] != null) {
            DateTime currentLimit = (tData['dateLimite'] as Timestamp).toDate();
            if (currentLimit.isBefore(plusProche)) {
              plusProche = currentLimit;
            }
          }
        }
        echeanceTexte = "${plusProche.day}/${plusProche.month}/${plusProche.year}";
      } catch (e) {
        echeanceTexte = "Aujourd'hui";
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsScreen(projectTitle: project.titre, pid: project.pid),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. LE TITRE RÉEL DU PROJET (ex: dghh)
                    Text(
                      project.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    
                    // 💡 2. LA DESCRIPTION DU PROJET (Remplace le texte en dur "Projet TeamFlow")
                    Text(
                      project.description.isNotEmpty ? project.description : "Aucune description fournie.",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    
                    const Text('Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xB3000000))),
                    const SizedBox(height: 6),
                    
                    // ÉQUIPE DYNAMIQUE DE FIRESTORE
                    Row(
                      children: [
                        Wrap(
                          children: project.membres.take(3).map((email) {
                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', isEqualTo: email)
                                  .limit(1)
                                  .get(),
                              builder: (context, userSnapshot) {
                                String initiales = email.substring(0, 2).toUpperCase();
                                String photoUrl = "";

                                if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                                  final uData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                  String fullName = uData['fullName'] ?? 'User';
                                  photoUrl = uData['photoUrl'] ?? '';
                                  initiales = fullName.split(' ').map((e) => e.isNotEmpty ? e : '').take(2).join().toUpperCase();
                                }

                                return Align(
                                  widthFactor: 0.75,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.gradientTop.withOpacity(0.15),
                                      backgroundImage: photoUrl.isNotEmpty && photoUrl.startsWith('/')
                                          ? FileImage(File(photoUrl))
                                          : null,
                                      child: photoUrl.isEmpty || photoUrl == 'local_cached_image'
                                          ? Text(initiales, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gradientTop))
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.add, size: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // 📊 METADONNÉES ET SUIVI DYNAMIQUE
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        
                        // 💡 3. DATE DYNAMIQUE (Affiche la date limite calculée ou l'échéance de la tâche)
                        Text(
                          echeanceTexte, 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.check_box_outlined, size: 14, color: AppColors.accentStatus),
                        const SizedBox(width: 6),
                        
                        // 💡 4. NOMBRE DE TÂCHES RÉELLES (ex: 1 Tasks au lieu de 0)
                        Text(
                          '$totalTasks ${totalTasks > 1 ? 'Tasks' : 'Task'}', 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 📊 5. ANNEAU DE PROGRESSION VECTORIEL RÉEL (ex: 100% au lieu de 0%)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: ProgressRing(
                  percentage: percentage,
                  size: 70.0,
                  strokeWidth: 7.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


