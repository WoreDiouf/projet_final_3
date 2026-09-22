import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 💡 Import indispensable
import '../utils/app_colors.dart';
import '../providers/project_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // 💡 DEVENU DYNAMIQUE : Tableau qui va stocker les e-mails des membres cochés
  final List<String> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    // Par sécurité sémantique, le créateur fait obligatoirement partie de son projet
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _selectedMembers.add(currentUser.email!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Créer un Projet',
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
                // CARD DU FORMULAIRE TEXTUEL
                Card(
                  color: Colors.white,
                  elevation: 2, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nom du projet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            hintText: 'Ex: Refonte de l\'application Mobile',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v!.isEmpty ? 'Veuillez entrer un titre pour le projet' : null,
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            hintText: 'Objectifs et détails du projet...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v!.isEmpty ? 'Veuillez entrer une description' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 👥 SECTION DYNAMIQUE : INVITER DES MEMBRES DEPUIS FIRESTORE
                const Text(
                  'Inviter des membres de l\'équipe',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                
                // Scan temps réel de la collection 'users' (Équivalent NoSQL de SELECT * FROM users)
                SizedBox(
                  height: 52,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userDocs = snapshot.data!.docs;

                      // On filtre pour ne pas s'inviter soi-même dans la liste (puisqu'on y est déjà par défaut)
                      final filteredUsers = userDocs.where((doc) {
                        return doc.get('email') != currentUser?.email;
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return const Text("Aucun autre collaborateur en base.", style: TextStyle(fontStyle: FontStyle.italic));
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final userData = filteredUsers[index].data() as Map<String, dynamic>;
                          final String email = userData['email'] ?? '';
                          final String fullName = userData['fullName'] ?? 'Sans nom';
                          
                          // Génération d'initiales propres (Ex: Amalia Kouyaté -> AK)
                          final String initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                          bool isSelected = _selectedMembers.contains(email);

                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: FilterChip(
                              label: Text("$fullName ($initials)"),
                              selected: isSelected,
                              selectedColor: AppColors.accentStatus.withOpacity(0.2),
                              checkmarkColor: AppColors.accentStatus,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isSelected ? AppColors.accentStatus : Colors.grey.shade300,
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedMembers.add(email);
                                  } else {
                                    _selectedMembers.remove(email);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 45),

                // BOUTON DE VALIDATION DÉGRADÉ
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
                      onTap: projectProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate() && currentUser != null) {
                                // 🚀 Envoi officiel de la liste de membres réels vers Cloud Firestore
                                bool success = await context.read<ProjectProvider>().addProject(
                                      titre: _titleController.text.trim(),
                                      description: _descController.text.trim(),
                                      createurId: currentUser.uid,
                                      membres: _selectedMembers, // Tableau dynamique d'e-mails
                                    );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Projet collaboratif créé avec succès !')),
                                  );Navigator.pop(context); // Retour
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: projectProvider.isLoading? 
                               const CircularProgressIndicator(color: Colors.white): const Text(
                                'CRÉER LE PROJET',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 0.5
                                ),
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