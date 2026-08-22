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

  /// Exclut les classes supprimees (suppression douce, voir `softDelete`) :
  /// on filtre cote client plutot qu'avec une clause `where` pour ne pas
  /// exiger que toutes les classes existantes aient deja le champ `deleted`
  /// (les classes creees avant l'ajout de cette fonctionnalite n'en ont
  /// pas, elles doivent quand meme apparaitre).
  Future<List<Classe>> list() async {
    final snap = await _classes.orderBy('nom').get();
    return snap.docs
        .where((d) => d.data()['deleted'] != true)
        .map(Classe.fromDoc)
        .toList();
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

  /// Suppression douce : marque `deleted: true` au lieu d'effacer le
  /// document. Les eleves/notes de la classe restent en base (pas de
  /// suppression en cascade), la classe disparait juste des listes.
  Future<void> softDelete(String classeId) =>
      _classes.doc(classeId).update({'deleted': true});

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
