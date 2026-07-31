import 'package:cloud_firestore/cloud_firestore.dart';

/// Document `enseignants/{uid}/classes/{classeId}/eleves/{eleveId}/notes/{noteId}`.
/// L'id du document est deterministe (`matiere__periode`) : une seule note par
/// matiere et par periode, l'ecriture ecrase simplement la precedente (upsert
/// naturel, pas besoin de chercher un doc existant avant d'ecrire).
class Note {
  final String id;
  final String matiere;
  final double valeur;
  final int coefficient;
  final String periode;
  final DateTime date;

  Note({
    required this.id,
    required this.matiere,
    required this.valeur,
    required this.coefficient,
    required this.periode,
    required this.date,
  });

  /// Les noms de matiere sont desormais saisis librement par l'enseignant :
  /// on retire '/' (illegal dans un id Firestore) pour rester sur un id
  /// deterministe simple.
  static String idFor(String matiere, String periode) =>
      '${matiere.replaceAll('/', '-')}__$periode';

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Note(
      id: doc.id,
      matiere: data['matiere'] as String? ?? '',
      valeur: (data['valeur'] as num?)?.toDouble() ?? 0,
      coefficient: (data['coefficient'] as num?)?.toInt() ?? 1,
      periode: data['periode'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'matiere': matiere,
    'valeur': valeur,
    'coefficient': coefficient,
    'periode': periode,
    'date': Timestamp.fromDate(date),
  };
}
