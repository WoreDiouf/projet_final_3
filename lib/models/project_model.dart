class ProjectModel {
  final String pid;
  final String titre;
  final String description;
  final String createurId;
  final List<String> membres;

  ProjectModel({
    required this.pid,
    required this.titre,
    required this.description,
    required this.createurId,
    required this.membres,
  });

  Map<String, dynamic> toMap() {
    return {
      'pid': pid,
      'titre': titre,
      'description': description,
      'createurId': createurId,
      'membres': membres,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      pid: map['pid'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      createurId: map['createurId'] ?? '',
      // Sécurisation de la conversion de la liste NoSQL dynamique en liste de chaînes (String)
      membres: List<String>.from(map['membres'] ?? []),
    );
  }
}