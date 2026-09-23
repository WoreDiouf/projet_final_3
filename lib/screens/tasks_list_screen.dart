import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TasksListScreen extends StatelessWidget {
  final String? filterStatut; // 💡 Reçoit 'enCours', 'termine' ou 'annule'
  final String title;         // Le titre dynamique de l'AppBar
  final bool masquerBoutonAjout; // 💡 Booléen de contrôle pour le bouton d'ajout

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

    // Préparation de la requête de base filtrée sur l'e-mail de l'utilisateur connecté
    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('assigneA', isEqualTo: userEmail);

    // 🔬 Injection algorithmique du filtre de statut si demandé par le cadre cliqué
    if (filterStatut != null) {
      query = query.where('statut', isEqualTo: filterStatut);
    }

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
          stream: query.snapshots(), // Écoute le flux NoSQL configuré sur mesure
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune tâche trouvée dans cette catégorie.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)));
            }

            final taskDocs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: taskDocs.length,
              itemBuilder: (context, index) {
                final data = taskDocs[index].data() as Map<String, dynamic>;
                final task = TaskModel.fromMap(data);
                final String docId = taskDocs[index].id;

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
                          // 💡 SÉCURITÉ DE FLUX : Si la tâche appartient à l'écran 'annule', on passe l'action à null pour la désactiver !
                          onChanged: filterStatut == 'annule' 
                              ? null // Rend l'émeraude disabled et impossible à cocher !
                              : (val) async {
                                  await context.read<TaskProvider>().toggleTaskStatus(docId, task.isDone);
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
                              // 🚨 Destruction physique définitive transitant par le Provider -> Service
                              await context.read<TaskProvider>().permanentlyDeleteTask(docId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tâche définitivement supprimée de la base.')),
                                );
                              }
                            } else {
                              // 📁 Envoi dans l'historique des annulées transitant par le Provider -> Service
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
