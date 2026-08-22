import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/matiere.dart';
import '../models/note.dart';

/// Acces Firestore pour `.../eleves/{eleveId}/notes` + calculs de moyennes.
///
/// L'id de chaque note est deterministe (`Note.idFor(matiere, periode)`), ce
/// qui permet de lire/ecrire une note precise par son id direct : pas besoin
/// de requete indexee pour la saisie ou le calcul de moyenne.
class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  NoteService(this.uid);

  CollectionReference<Map<String, dynamic>> _notes(
    String classeId,
    String eleveId,
  ) => _db
      .collection('enseignants')
      .doc(uid)
      .collection('classes')
      .doc(classeId)
      .collection('eleves')
      .doc(eleveId)
      .collection('notes');

  Future<void> upsert(
    String classeId,
    String eleveId, {
    required String matiere,
    required double valeur,
    required int coefficient,
    required String periode,
  }) {
    final id = Note.idFor(matiere, periode);
    final note = Note(
      id: id,
      matiere: matiere,
      valeur: valeur,
      coefficient: coefficient,
      periode: periode,
      date: DateTime.now(),
    );
    return _notes(classeId, eleveId).doc(id).set(note.toMap());
  }

  Future<void> supprimer(
    String classeId,
    String eleveId, {
    required String matiere,
    required String periode,
  }) {
    final id = Note.idFor(matiere, periode);
    return _notes(classeId, eleveId).doc(id).delete();
  }

  /// Toutes les notes d'un eleve pour une periode (une lecture par matiere de
  /// la classe, via l'id deterministe : pas de requete `where` necessaire).
  /// `matieres` vient de `Classe.matieres` : chaque classe a ses propres
  /// matieres, ce n'est plus une liste globale fixe.
  Future<List<Note>> notesEleve(
    String classeId,
    String eleveId,
    String periode,
    List<Matiere> matieres,
  ) async {
    final futures = matieres.map(
      (m) => _notes(classeId, eleveId).doc(Note.idFor(m.nom, periode)).get(),
    );
    final docs = await Future.wait(futures);
    return docs.where((d) => d.exists).map(Note.fromDoc).toList();
  }

  /// Moyenne ponderee par coefficient, ou null si aucune note saisie.
  static double? moyennePonderee(List<Note> notes) {
    if (notes.isEmpty) return null;
    final sommePoints = notes.fold<double>(
      0,
      (a, n) => a + n.valeur * n.coefficient,
    );
    final sommeCoeff = notes.fold<int>(0, (a, n) => a + n.coefficient);
    if (sommeCoeff == 0) return null;
    return _arrondir(sommePoints / sommeCoeff);
  }

  static double _arrondir(double v) => (v * 10).round() / 10;
}

class StatistiquesClasse {
  final int effectif;
  final double? moyenneGenerale;
  final double? moyenneMin;
  final double? moyenneMax;

  StatistiquesClasse({
    required this.effectif,
    this.moyenneGenerale,
    this.moyenneMin,
    this.moyenneMax,
  });

  factory StatistiquesClasse.from(List<double?> moyennes) {
    final valeurs = moyennes.whereType<double>().toList();
    if (valeurs.isEmpty) {
      return StatistiquesClasse(effectif: moyennes.length);
    }
    final moyenne = NoteService._arrondir(
      valeurs.reduce((a, b) => a + b) / valeurs.length,
    );
    return StatistiquesClasse(
      effectif: moyennes.length,
      moyenneGenerale: moyenne,
      moyenneMin: valeurs.reduce((a, b) => a < b ? a : b),
      moyenneMax: valeurs.reduce((a, b) => a > b ? a : b),
    );
  }
}
