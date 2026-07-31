import 'package:cloud_firestore/cloud_firestore.dart';

import 'matiere.dart';

/// Document `enseignants/{uid}/classes/{classeId}`.
/// `effectif` est denormalise (maj via FieldValue.increment a chaque ajout/
/// suppression d'eleve) pour eviter de compter la sous-collection a chaque
/// lecture du tableau de bord.
/// `matieres` est propre a la classe (l'enseignant peut en ajouter/retirer) ;
/// les classes creees avant l'ajout de ce champ retombent sur la liste par
/// defaut, pas de migration manuelle necessaire.
class Classe {
  final String id;
  final String nom;
  final String niveau;
  final int effectif;
  final List<Matiere> matieres;

  Classe({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.effectif,
    required this.matieres,
  });

  factory Classe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final matieresData = data['matieres'] as List<dynamic>?;
    return Classe(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
      niveau: data['niveau'] as String? ?? '',
      effectif: (data['effectif'] as num?)?.toInt() ?? 0,
      matieres: matieresData == null || matieresData.isEmpty
          ? kMatieresDefaut
          : matieresData
                .map((m) => Matiere.fromMap(m as Map<String, dynamic>))
                .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'niveau': niveau,
    'effectif': effectif,
    'matieres': matieres.map((m) => m.toMap()).toList(),
  };
}
