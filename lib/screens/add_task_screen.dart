import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final String projectPid;

  const AddTaskScreen({
    super.key,
    required this.projectPid
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _assignedMember = 'Amalia Kouyaté'; // Valeur par défaut de votre maquette

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  // Affiche le calendrier natif du smartphone
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _selectedMembersContainsEmail(List<DocumentSnapshot> docs, String? email) {
    if (email == null) return false;
    return docs.any((doc) => doc.get('email') == email);
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Écoute de l'état de chargement du TaskProvider
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Créer une Tâche',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD DU FORMULAIRE DE TÂCHE
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Intitulé de la tâche', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _taskTitleController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            hintText: 'Ex: Configurer Cloud Firestore',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v!.isEmpty ? 'Veuillez entrer un intitulé pour la tâche' : null,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Description', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _taskDescController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            hintText: 'Détails des livrables attendus...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Date Limite / Échéance', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', 
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                const Icon(Icons.calendar_today_rounded, color: AppColors.gradientTop, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Assigner à un collaborateur', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('projects')
                              .doc(widget.projectPid) // Récupère l'identifiant unique du projet parent
                              .snapshots(),
                          builder: (context, projectSnapshot) {
                            if (!projectSnapshot.hasData) {
                              return const Center(child: LinearProgressIndicator());
                            }

                            if (!projectSnapshot.data!.exists) {
                              return const Text("Erreur : Projet introuvable.", style: TextStyle(color: Colors.redAccent));
                            }

                            // Extraction de la liste d'e-mails des membres stockée dans la console Firestore
                            final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;
                            final List<dynamic> membresDuProjet = projectData['membres'] ?? [];

                            if (membresDuProjet.isEmpty) {
                              return const Text("Aucun membre associé à ce projet.", style: TextStyle(color: Colors.redAccent));
                            }

                            // 💡 2. SECOND STREAM : On filtre la table users pour n'afficher QUE les personnes présentes dans 'membres'
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', whereIn: membresDuProjet) // 🔬 Le filtre d'étanchéité collaboratif se situe ici !
                                  .snapshots(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const Center(child: LinearProgressIndicator());
                                }

                                final userDocs = userSnapshot.data!.docs;

                                if (userDocs.isEmpty) {
                                  return const Text("Aucun profil utilisateur correspondant trouvé.", style: TextStyle(color: Colors.redAccent));
                                }

                                // Initialisation automatique par sécurité sur le premier membre de l'équipe
                                if (_assignedMember == 'Amalia Kouyaté' || _assignedMember == null || !_selectedMembersContainsEmail(userDocs, _assignedMember)) {
                                  _assignedMember = userDocs.first.get('email') as String;
                                }

                                return DropdownButtonFormField<String>(
                                  value: _assignedMember,
                                  isExpanded: true, 
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                  // Remplissage dynamique des lignes du menu au pixel près
                                  items: userDocs.map((doc) {
                                    final userData = doc.data() as Map<String, dynamic>;
                                    final String email = userData['email'] ?? '';
                                    final String fullName = userData['fullName'] ?? 'Sans nom';

                                    return DropdownMenuItem<String>(
                                      value: email, // L'e-mail unique sert de clé d'assignation pour le Dashboard personnel
                                      child: Text(
                                        "$fullName ($email)", 
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _assignedMember = value;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // BOUTON DE VALIDATION DÉGRADÉ DYNAMIQUE
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.appLinearGradient, 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: taskProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                // 🚀 Envoi officiel des données vers le TaskProvider puis Cloud Firestore
                                bool success = await context.read<TaskProvider>().addTask(
                                      titre: _taskTitleController.text.trim(),
                                      description: _taskDescController.text.trim(),
                                      dateLimite: _selectedDate,
                                      assigneA: _assignedMember!,
                                      projectId: widget.projectPid
                                    );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tâche ajoutée avec succès dans Firestore !')),
                                  );
                                  Navigator.pop(context); // Revient automatiquement en arrière
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(taskProvider.error ?? 'Erreur lors de la création'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: taskProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'AJOUTER LA TÂCHE',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

