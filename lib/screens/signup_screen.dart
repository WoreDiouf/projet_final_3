import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projet_final_3/providers/auth_controller.dart';
import 'package:projet_final_3/screens/dashboard_screen.dart';
import 'package:projet_final_3/utils/app_colors.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _imageFile; // Stockera la photo capturée par l'appareil photo
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 💡 A. Fonction générique de capture d'image pour l'inscription (Galerie ou Appareil Photo)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(
          pickedFile.path,
        ); // Stocke le fichier image sélectionné
      });
    }
  }

  // 📱 B. Feuille de choix (Bottom Sheet) identique à l'écran de modification
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.gradientTop,
                ),
                title: const Text('Prendre une photo (Appareil Photo)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(
                    ImageSource.camera,
                  ); // 📸 Déclenche l'appareil photo de l'émulateur
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color.fromARGB(255, 8, 5, 98),
                ),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(
                    ImageSource.gallery,
                  ); // 🖼️ Déclenche la galerie de l'émulateur
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.appLinearGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 25.0, 20.0, 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Créer un Compte',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFDCE3F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : null,
                                  child: _imageFile == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 45,
                                          color: Color.fromARGB(255, 14, 133, 211),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showImageSourceActionSheet(context),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.6,
                                      ),
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : null,
                                      child: _imageFile == null
                                          ? const Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 32,
                                              color: Color.fromARGB(255, 14, 133, 211),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Nom complet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: Cheikhouna Gueye',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v!.isEmpty
                                ? 'Veuillez entrer votre nom complet'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Nom d\'utilisateur',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization
                                .none, // Désactive la majuscule auto du clavier
                            autocorrect: false, // Désactive les corrections automatiques du smartphone
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Ex: dioufy (minuscules uniquement)",
                            ),

                            // SÉCURITÉ ALGORITHMIQUE : Le validateur bloque les majuscules et les espaces
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Veuillez saisir un nom d'utilisateur";
                              }
                              if (v.contains(' ')) {
                                return "Les espaces sont interdits dans le nom d'utilisateur";
                              }
                              // Expression régulière (RegEx) qui autorise UNIQUEMENT les lettres minuscules et les chiffres
                              if (!RegExp(r'^[a-z0-9]+$').hasMatch(v)) {
                                return "Le nom d'utilisateur doit être uniquement en minuscules";
                              }
                              return null; // Tout est parfait
                            },
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: collaborateur@teamflow.com',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) =>
                                v!.contains('@') ? null : 'Email invalide',
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Mot de passe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: '••••••••',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? '6 caractères minimum' : null,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Confirmer Mot de passe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: '••••••••',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v == _passwordController.text
                                ? null
                                : 'Mots de passe différents',
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  activeColor: AppColors.accentStatus,
                                  onChanged: (val) {
                                    setState(() {
                                      _agreeToTerms = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'J\'accepte les conditions d\'utilisation',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.appLinearGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: !_agreeToTerms
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          bool success = await authController
                                              .register(
                                                email: _emailController.text
                                                    .trim(),
                                                password: _passwordController
                                                    .text
                                                    .trim(),
                                                nom: _nameController.text
                                                    .trim(),
                                                fullName: _fullNameController
                                                    .text
                                                    .trim(),
                                                imageFile: _imageFile,
                                              );

                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Inscription réussie !',
                                                    ),
                                                  ),
                                                );
                                            // Redirection automatique vers l'Écran 4 (Dashboard) après succès
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const DashboardScreen(),
                                              ),
                                            );
                                          } else if (context.mounted) {
                                            // Affiche l'erreur renvoyée par Firebase (ex: e-mail déjà utilisé, mot de passe trop court)
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  authController.error ??
                                                      'Échec de l\'inscription',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: authController.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        ) // Spinner pendant le chargement
                                      : const Text(
                                          'S\'INSCRIRE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Déjà membre ? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5385F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
