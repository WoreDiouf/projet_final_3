class UserModel {
  final String uid;
  final String fullName;
  final String nom;
  final String email;
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.nom,
    required this.email,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'nom': nom,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }
}