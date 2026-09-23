import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TasksListScreen extends StatelessWidget {
  final String? filterStatut; // Reçoit 'enCours', 'termine' ou 'annule'
  final String title;         // Le titre dynamique de l'AppBar
  final bool masquerBoutonAjout; // Booléen de contrôle pour le bouton d'ajout

  const TasksListScreen({
    super.key,
    this.filterStatut,
    this.title = 'Mes Tâches Générales',
    this.masquerBoutonAjout = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String userEmail = currentUser?.email ?? "";

    // 🔬 Requête globale sur l'utilisateur connecté (Le tri fin s'opère en mémoire locale)
    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('assigneA', isEqualTo: userEmail);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gradientTop),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune tâche trouvée.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)));
            }

            final allDocs = snapshot.data!.docs;
            List<DocumentSnapshot> filteredDocs = [];

            // 🧠 ALGORITHME DE SYNCHRONISATION DU PIPELINE D'ÉQUIPE D-CLIC
            if (filterStatut == 'termine') {
              // Extraction des tâches complétées fixes
              filteredDocs = allDocs.where((d) => (d.data() as Map)['isDone'] == true || (d.data() as Map)['statut'] == 'termine').toList();
            } else if (filterStatut == 'annule') {
              // Extraction des tâches archivées/mises au rebut
              filteredDocs = allDocs.where((d) => (d.data() as Map)['statut'] == 'annule').toList();
            } else if (filterStatut == 'enCours' || filterStatut == 'traitement') {
              // Étape 1 : Isoler toutes les tâches actives (Ni finies, ni annulées)
              List<DocumentSnapshot> actives = allDocs.where((d) {
                final Map data = d.data() as Map;
                bool valide = data['isDone'] != true && data['statut'] != 'termine' && data['statut'] != 'annule';
                return valide;
              }).toList();

              // Étape 2 : Tri chronologique strict par date d'échéance la plus proche
              actives.sort((a, b) {
                DateTime dateA = ((a.data() as Map)['dateLimite'] as Timestamp).toDate();
                DateTime dateB = ((b.data() as Map)['dateLimite'] as Timestamp).toDate();
                return dateA.compareTo(dateB);
              });

              // Étape 3 : Répartition exclusive selon la règle de file d'attente
              if (actives.isNotEmpty) {
                if (filterStatut == 'enCours') {
                  // Seule la tâche la plus urgente (la première) est acceptée ici
                  filteredDocs = [actives.first];
                } else if (filterStatut == 'traitement') {
                  // Toutes les autres tâches en attente forment la file de traitement
                  filteredDocs = actives.sublist(1);
                }
              }
            } else {
              filteredDocs = allDocs; // Mode général de secours
            }

            if (filteredDocs.isEmpty) {
              return const Center(child: Text("Aucune tâche dans cette catégorie.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                final task = TaskModel.fromMap(data);
                final String docId = filteredDocs[index].id;

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: task.isDone,
                          activeColor: AppColors.accentStatus,
                          onChanged: filterStatut == 'annule' 
                              ? null // Désactivation matérielle si la tâche est dans la corbeille
                              : (val) async {
                                  // 🚀 On transmet l'état actuel (task.isDone) que le Provider va inverser proprement en base NoSQL
                                  await context.read<TaskProvider>().toggleTaskStatus(docId, task.isDone,data['statut'] ?? 'enCours',);
                                },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.titre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: task.isDone ? TextDecoration.lineThrough : null)),
                              Text("Échéance : ${task.dateLimite.day}/${task.dateLimite.month}/${task.dateLimite.year}", style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            filterStatut == 'annule' ? Icons.delete_forever_rounded : Icons.delete_outline_rounded, 
                            color: Colors.redAccent, 
                            size: 20,
                          ),
                          onPressed: () async {
                            if (filterStatut == 'annule') {
                              await context.read<TaskProvider>().permanentlyDeleteTask(docId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tâche définitivement supprimée de la base.')),
                                );
                              }
                            } else {
                              await context.read<TaskProvider>().removeTask(docId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}