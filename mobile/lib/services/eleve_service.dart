import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/eleve.dart';
import 'classe_service.dart';

/// Acces Firestore pour `enseignants/{uid}/classes/{classeId}/eleves`.
class EleveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  final ClasseService _classeService;
  EleveService(this.uid) : _classeService = ClasseService(uid);

  CollectionReference<Map<String, dynamic>> _eleves(String classeId) => _db
      .collection('enseignants')
      .doc(uid)
      .collection('classes')
      .doc(classeId)
      .collection('eleves');

  Future<List<Eleve>> listForClasse(String classeId) async {
    final snap = await _eleves(classeId).orderBy('nom').get();
    return snap.docs.map(Eleve.fromDoc).toList();
  }

  Future<Eleve> create(
    String classeId, {
    required String nom,
    required String prenom,
    required String telephoneParent,
    String? nomParent,
  }) async {
    final ref = await _eleves(classeId).add({
      'nom': nom,
      'prenom': prenom,
      'telephoneParent': telephoneParent,
      'nomParent': ?nomParent,
    });
    await _classeService.incrementEffectif(classeId, 1);
    final doc = await ref.get();
    return Eleve.fromDoc(doc);
  }

  Future<void> update(
    String classeId,
    String eleveId, {
    required String nom,
    required String prenom,
    required String telephoneParent,
    String? nomParent,
  }) {
    return _eleves(classeId).doc(eleveId).update({
      'nom': nom,
      'prenom': prenom,
      'telephoneParent': telephoneParent,
      'nomParent': ?nomParent,
    });
  }

  Future<void> delete(String classeId, String eleveId) async {
    await _eleves(classeId).doc(eleveId).delete();
    await _classeService.incrementEffectif(classeId, -1);
  }
}
