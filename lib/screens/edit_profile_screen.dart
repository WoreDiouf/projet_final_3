import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projet_final_3/providers/auth_controller.dart';
import 'package:provider/provider.dart'; 
import '../utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nameController = TextEditingController();
  
  File? _imageFile; // Stocke la nouvelle photo sélectionnée
  String _currentPhotoUrl = ""; // Stocke l'ancienne photo existante
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charge les données actuelles depuis Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _fullNameController.text = doc.data()!['fullName'] ?? '';
          _nameController.text = doc.data()!['nom'] ?? '';
          _currentPhotoUrl = doc.data()!['photoUrl'] ?? '';
        });
      }
    }
  }

  // Fonction générique de capture d'image selon la source matérielle
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Feuille de choix (Bottom Sheet) qui surgit élégamment du bas de l'écran
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.gradientTop),
                title: const Text('Prendre une photo (Appareil Photo)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera); // 📸 Déclenche l'appareil photo
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.gradientTop),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery); // 🖼️ Déclenche la galerie
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Modifier le Profil', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.appLinearGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 📸 ZONE PHOTO INTÉRACTIVE ET CLIQUABLE
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context), 
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            // Gestion de l'affichage de la photo (Nouvelle > Ancienne > Icône vide)
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_currentPhotoUrl.isNotEmpty && _currentPhotoUrl != 'local_cached_image'
                                    ? NetworkImage(_currentPhotoUrl) as ImageProvider
                                    : null),
                            child: _imageFile == null && (_currentPhotoUrl.isEmpty || _currentPhotoUrl == 'local_cached_image')
                                ? const Icon(Icons.person, size: 55, color: Colors.white)
                                : null,
                          ),
                          // Petit badge "+" vert émeraude pour indiquer qu'on peut cliquer
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.accentStatus,
                            child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ⚪ GRAND BLOC BLANC DU FORMULAIRE
                    Card(
                      color: Color(0xFFDCE3F0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nom complet', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                              validator: (v) => v!.isEmpty ? 'Veuillez entrer votre nom complet' : null,
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              "Nom d'utilisateur", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xB3000000)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                              validator: (v) => v!.isEmpty ? "Veuillez entrer un nom d'utilisateur" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // 🚀 BOUTON DE VALIDATION
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFFDCE3F0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: authController.isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                String photoPathToSave = _imageFile != null ? _imageFile!.path : _currentPhotoUrl;
                                if (photoPathToSave.isEmpty) photoPathToSave = 'local_cached_image';

                                // 🚀 Appel officiel de la couche logicielle Provider (Rien n'est en dur)
                                bool success = await context.read<AuthController>().updateProfile(
                                      uid: user.uid,
                                      fullName: _fullNameController.text.trim(),
                                      nom: _nameController.text.trim(),
                                      photoUrl: photoPathToSave,
                                    );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profil et photo mis à jour avec succès !')),
                                  );
                                  Navigator.pop(context);
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading 
                                ? const CircularProgressIndicator(color: AppColors.gradientTop)
                                : const Text(
                                  'ENREGISTRER LES MODIFICATIONS',
                                  style: TextStyle(
                                    color: AppColors.gradientTop, 
                                    fontSize: 15, 
                                    fontWeight: FontWeight.bold, 
                                    letterSpacing: 0.5
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}