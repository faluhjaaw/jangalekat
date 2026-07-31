import 'package:cloud_firestore/cloud_firestore.dart';

/// Document `enseignants/{uid}/classes/{classeId}/eleves/{eleveId}`.
class Eleve {
  final String id;
  final String nom;
  final String prenom;
  final String telephoneParent;
  final String? nomParent;

  Eleve({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephoneParent,
    this.nomParent,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return (p + n).toUpperCase();
  }

  factory Eleve.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Eleve(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephoneParent: data['telephoneParent'] as String? ?? '',
      nomParent: data['nomParent'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'prenom': prenom,
    'telephoneParent': telephoneParent,
    if (nomParent != null) 'nomParent': nomParent,
  };
}
