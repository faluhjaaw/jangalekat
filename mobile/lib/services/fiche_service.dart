import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fiche_contenu.dart';
import '../models/fiche_cours.dart';

/// Acces Firestore pour `enseignants/{uid}/fiches` (fiches de cours generees
/// par Gemini, enregistrees par l'enseignant pour consultation ulterieure).
class FicheService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  FicheService(this.uid);

  CollectionReference<Map<String, dynamic>> get _fiches =>
      _db.collection('enseignants').doc(uid).collection('fiches');

  Future<FicheCours> enregistrer({
    required String matiere,
    required String niveau,
    required String theme,
    required FicheContenu contenu,
    required String langue,
  }) async {
    final fiche = FicheCours(
      id: '',
      matiere: matiere,
      niveau: niveau,
      theme: theme,
      contenu: contenu,
      langue: langue,
      dateCreation: DateTime.now(),
    );
    final ref = await _fiches.add(fiche.toMap());
    final doc = await ref.get();
    return FicheCours.fromDoc(doc);
  }

  Future<List<FicheCours>> historique({int limit = 100}) async {
    final snap = await _fiches
        .orderBy('dateCreation', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(FicheCours.fromDoc).toList();
  }

  Future<void> supprimer(String ficheId) => _fiches.doc(ficheId).delete();

  Future<void> modifier({
    required String ficheId,
    required String theme,
    required FicheContenu contenu,
  }) => _fiches.doc(ficheId).update({
    'theme': theme,
    'contenu': jsonEncode(contenu.toJson()),
  });
}
