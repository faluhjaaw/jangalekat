import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'fiche_contenu.dart';

/// Document `enseignants/{uid}/fiches/{ficheId}`.
/// `contenu` est le JSON encode de [FicheContenu] : un seul champ texte cote
/// Firestore (schema simple), structure cote app pour l'affichage/edition.
class FicheCours {
  final String id;
  final String matiere;
  final String niveau;
  final String theme;
  final FicheContenu contenu;
  final String langue;
  final DateTime dateCreation;

  FicheCours({
    required this.id,
    required this.matiere,
    required this.niveau,
    required this.theme,
    required this.contenu,
    required this.langue,
    required this.dateCreation,
  });

  factory FicheCours.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final contenuRaw = data['contenu'] as String? ?? '{}';
    Map<String, dynamic> contenuJson;
    try {
      contenuJson = jsonDecode(contenuRaw) as Map<String, dynamic>;
    } catch (_) {
      contenuJson = {};
    }
    return FicheCours(
      id: doc.id,
      matiere: data['matiere'] as String? ?? '',
      niveau: data['niveau'] as String? ?? '',
      theme: data['theme'] as String? ?? '',
      contenu: FicheContenu.fromJson(contenuJson),
      langue: data['langue'] as String? ?? 'fr',
      dateCreation:
          (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'matiere': matiere,
    'niveau': niveau,
    'theme': theme,
    'contenu': jsonEncode(contenu.toJson()),
    'langue': langue,
    'dateCreation': Timestamp.fromDate(dateCreation),
  };
}
