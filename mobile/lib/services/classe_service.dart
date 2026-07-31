import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/classe.dart';
import '../models/matiere.dart';

/// Acces Firestore pour `enseignants/{uid}/classes`.
class ClasseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  ClasseService(this.uid);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection('enseignants').doc(uid).collection('classes');

  Future<List<Classe>> list() async {
    final snap = await _classes.orderBy('nom').get();
    return snap.docs.map(Classe.fromDoc).toList();
  }

  Future<Classe> create({required String nom, required String niveau}) async {
    final ref = await _classes.add({
      'nom': nom,
      'niveau': niveau,
      'effectif': 0,
      'matieres': kMatieresDefaut.map((m) => m.toMap()).toList(),
    });
    final doc = await ref.get();
    return Classe.fromDoc(doc);
  }

  Future<void> update(
    String classeId, {
    required String nom,
    required String niveau,
  }) {
    return _classes.doc(classeId).update({'nom': nom, 'niveau': niveau});
  }

  Future<void> delete(String classeId) => _classes.doc(classeId).delete();

  /// Maj atomique du compteur d'effectif (evite de recompter la sous-collection
  /// a chaque fois qu'on affiche la liste des classes).
  Future<void> incrementEffectif(String classeId, int delta) {
    return _classes.doc(classeId).update({
      'effectif': FieldValue.increment(delta),
    });
  }

  /// Remplace la liste complete des matieres de la classe (ajout/suppression
  /// gerees cote ecran, on persiste juste le resultat).
  Future<void> updateMatieres(String classeId, List<Matiere> matieres) {
    return _classes.doc(classeId).update({
      'matieres': matieres.map((m) => m.toMap()).toList(),
    });
  }
}
