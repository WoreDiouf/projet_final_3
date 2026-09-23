import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_final_3/screens/edit_profile_screen.dart';
import 'package:projet_final_3/screens/projects_list_screen.dart';
import 'package:projet_final_3/screens/tasks_list_screen.dart';

import '../utils/app_colors.dart';
import '../models/task_model.dart';
import 'add_project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Automatisation de la date du jour en Français
  String _getAutomatedDate() {
    final now = DateTime.now();
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return "Aujourd'hui\n${now.day} ${mois[now.month - 1]} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    // 👤 Récupération de l'utilisateur connecté via Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    // On utilise son e-mail comme identifiant unique pour le filtrage des assignations NoSQL
    final String userEmail = currentUser?.email ?? "";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bienvenue',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            size: 30,
            color: AppColors.gradientTop,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String photoUrl = "";
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  photoUrl = userData['photoUrl'] ?? "";
                }

                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      photoUrl.isNotEmpty && photoUrl.startsWith('/')
                      ? FileImage(
                          File(photoUrl),
                        ) // 💡 Charge également la photo dans l'AppBar !
                      : (photoUrl.isNotEmpty && photoUrl.startsWith('http')
                            ? NetworkImage(photoUrl) as ImageProvider
                            : null),
                  child: photoUrl.isEmpty
                      ? const Icon(
                          Icons.account_circle,
                          size: 40,
                          color: AppColors.gradientTop,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String displayName = "Chargement...";
                String displayEmail = FirebaseAuth.instance.currentUser?.email ?? "Session active";
                String photoUrl = "";

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  displayName = userData['fullName'] ?? "Collaborateur";
                  photoUrl = userData['photoUrl'] ?? "";
                }

                // 💡 LE CHANGEMENT CHIRURGICAL SE SITUE ICI :
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50.0, bottom: 24.0, left: 16.0, right: 16.0),
                  decoration: const BoxDecoration(
                    gradient: AppColors.appLinearGradient, // Votre dégradé linéaire officiel
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. L'AVATAR : Agrandi, monté et centré au pixel près
                      Center(
                        child: CircleAvatar(
                          radius: 46, // Taille augmentée pour la démo
                          backgroundColor: Colors.white,
                          backgroundImage: photoUrl.isNotEmpty && photoUrl.startsWith('/')
                              ? FileImage(File(photoUrl)) // Image locale capturée
                              : (photoUrl.isNotEmpty && photoUrl.startsWith('http')
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : null),
                          child: photoUrl.isEmpty || photoUrl == 'local_cached_image'
                              ? const Icon(Icons.person, size: 45, color: AppColors.gradientTop)
                              : null,
                        ),
                      ),
                      
                      const SizedBox(height: 14),

                      // 2. LE NOM : Parfaitement centré
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 4),

                      // 3. L'EMAIL + LE BOUTON CRAYON : Alignés au centre
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayEmail,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                            tooltip: 'Modifier le profil',
                            onPressed: () {
                              Navigator.pop(context); // Ferme le Drawer
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ); // Fin du Container de remplacement
              },
            ),
            
            // 📋 LE RESTE DES BOUTONS DU MENU (Inchangés et stables)
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: AppColors.gradientTop),
              title: const Text('Tableau de Bord', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_shared_rounded, color: Colors.black54),
              title: const Text('Mes Projets', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_rounded, color: Colors.black54),
              title: const Text('Mes Tâches', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TasksListScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getAutomatedDate(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 30),

              // 📊 SECTION 1 : GRILLE DYNAMIQUE FILTRÉE UNIQUEMENT SUR L'UTILISATEUR CONNECTÉ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('assigneA', isEqualTo: userEmail) // Uniquement mes tâches
                    .snapshots(),
                builder: (context, snapshot) {
                  int countEnCours = 0;
                  int countTraitement = 0;
                  int countTermine = 0;
                  int countAnnule = 0;

                  if (snapshot.hasData) {
                    final allDocs = snapshot.data!.docs;

                    // 🔴 1. Tri immédiat des tâches terminées et annulées fixes
                    final terminees = allDocs.where((d) => (d.data() as Map)['isDone'] == true || (d.data() as Map)['statut'] == 'termine').toList();
                    final annulees = allDocs.where((d) => (d.data() as Map)['statut'] == 'annule').toList();

                    countTermine = terminees.length;
                    countAnnule = annulees.length;
                    // 🔵 2. Extraction des tâches véritablement ACTIVES (ni finies, ni annulées)
                    List<DocumentSnapshot> tachesActives = allDocs.where((d) {
                      final Map data = d.data() as Map;
                      bool nonFinie = data['isDone'] != true && data['statut'] != 'termine';
                      bool nonAnnulee = data['statut'] != 'annule';
                      return nonFinie && nonAnnulee;
                    }).toList();

                    // 🧠 3. ALGORITHME DE TRADING TEMPOREL D-CLIC
                    if (tachesActives.isNotEmpty) {
                      // On trie mathématiquement les tâches de la plus urgente à la plus lointaine
                      tachesActives.sort((a, b) {
                        DateTime dateA = ((a.data() as Map)['dateLimite'] as Timestamp).toDate();
                        DateTime dateB = ((b.data() as Map)['dateLimite'] as Timestamp).toDate();
                        return dateA.compareTo(dateB); // Ordre chronologique croissant
                      });

                      // La première (la plus urgente) prend OBLIGATOIREMENT le statut "En cours"
                      countEnCours = 1;

                      // Toutes les autres (les suivantes en attente) basculent dans "Traitement" !
                      countTraitement = tachesActives.length - 1;
                    }
                  }

                  // 🎛️ COUPLAGE GÉOMÉTRIQUE AVEC LES 4 CADRES DU DASHBOARD
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    children: [
                      // CADRE 1 : EN COURS (La plus urgente)
                      _buildStatCard(
                        title: 'EN COURS', 
                        count: countEnCours.toString().padLeft(2, '0'), 
                        accentColor: const Color(0xFF4A65D2), 
                        icon: Icons.play_arrow_rounded,
                      ),
                      // CADRE 2 : TRAITEMENT (La file d'attente dynamique)
                      _buildStatCard(
                        title: 'TRAITEMENT', 
                        count: countTraitement.toString().padLeft(2, '0'), 
                        accentColor: const Color(0xFF4CE3B2), 
                        icon: Icons.sync_rounded,
                      ),
                      // CADRE 3 : TERMINÉ
                      _buildStatCard(
                        title: 'TERMINÉ', 
                        count: countTermine.toString().padLeft(2, '0'), 
                        accentColor: const Color(0xFF4CBCE3), 
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      // CADRE 4 : ANNULÉ (Géré par votre Soft Delete du Service)
                      _buildStatCard(
                        title: 'ANNULÉ', 
                        count: countAnnule.toString().padLeft(2, '0'), 
                        accentColor: const Color(0xFF7952E5), 
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 35),

              const Text(
                "Mes tâches d'équipe",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // 📋 SECTION 2 : LISTE DES TÂCHES FILTRÉE UNIQUEMENT SUR L'UTILISATEUR CONNECTÉ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where(
                      'assigneA',
                      isEqualTo: userEmail,
                    ) // 💡 FILTRE STRATEGIQUE NoSQL
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        "Vous n'avez aucune tâche assignée pour le moment.",
                        style: TextStyle(
                          color: Colors.black45,
                          fontStyle: FontStyle.italic,
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

                      return _buildTaskItem(
                        docId: taskDocs[index].id,
                        title: task.titre,
                        subtitle: "Assigné à moi",
                        isCompleted: task.isDone,
                        // 🚀 AJOUT : On transmet la valeur textuelle du statut NoSQL à la méthode !
                        taskStatut: data['statut'] ?? 'enCours', 
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProjectScreen()),
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            gradient: AppColors.appLinearGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  Icon(Icons.north_east_rounded, color: accentColor, size: 16),
                ],
              ),
            ),
            Center(
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  color: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String docId,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String taskStatut,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                activeColor: AppColors.accentStatus,
                // 💡 BLOCAGE SI ANNULÉ : Si le statut NoSQL est 'annule', onChanged passe à null pour griser et bloquer le clic !
                onChanged: taskStatut == 'annule'
                    ? null 
                    : (val) async {
                        bool newStatus = val ?? false;
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(docId)
                            .update({
                              'isDone': newStatus,
                              'statut': newStatus ? 'termine' : 'enCours',
                            });
                      },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
