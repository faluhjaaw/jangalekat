/// Profil enseignant, stocke dans le document `enseignants/{uid}`.
/// Le `uid` est celui de Firebase Auth, pas un id genere par Firestore.
class Enseignant {
  final String uid;
  final String nom;
  final String telephone;
  final String? ecole;

  Enseignant({
    required this.uid,
    required this.nom,
    required this.telephone,
    this.ecole,
  });

  factory Enseignant.fromMap(String uid, Map<String, dynamic> data) =>
      Enseignant(
        uid: uid,
        nom: data['nom'] as String? ?? '',
        telephone: data['telephone'] as String? ?? '',
        ecole: data['ecole'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'telephone': telephone,
    if (ecole != null) 'ecole': ecole,
  };
}
