/// Profil enseignant, stocke dans le document `enseignants/{uid}`.
/// Le `uid` est celui de Firebase Auth, pas un id genere par Firestore.
class Enseignant {
  final String uid;
  final String nom;
  final String email;
  final String? ecole;
  final String? telephone;
  final String? ia;
  final String? ief;

  Enseignant({
    required this.uid,
    required this.nom,
    required this.email,
    this.ecole,
    this.telephone,
    this.ia,
    this.ief,
  });

  factory Enseignant.fromMap(String uid, Map<String, dynamic> data) =>
      Enseignant(
        uid: uid,
        nom: data['nom'] as String? ?? '',
        email: data['email'] as String? ?? '',
        ecole: data['ecole'] as String?,
        telephone: data['telephone'] as String?,
        ia: data['ia'] as String?,
        ief: data['ief'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'email': email,
    if (ecole != null) 'ecole': ecole,
    if (telephone != null) 'telephone': telephone,
    if (ia != null) 'ia': ia,
    if (ief != null) 'ief': ief,
  };
}
