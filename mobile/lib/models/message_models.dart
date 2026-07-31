import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMessage { felicitations, convocation, alerte, groupe, personnalise }

extension TypeMessageWire on TypeMessage {
  String get wireName => switch (this) {
    TypeMessage.felicitations => 'felicitations',
    TypeMessage.convocation => 'convocation',
    TypeMessage.alerte => 'alerte',
    TypeMessage.groupe => 'groupe',
    TypeMessage.personnalise => 'personnalise',
  };

  static TypeMessage fromWire(String value) => switch (value) {
    'felicitations' => TypeMessage.felicitations,
    'convocation' => TypeMessage.convocation,
    'alerte' => TypeMessage.alerte,
    'groupe' => TypeMessage.groupe,
    _ => TypeMessage.personnalise,
  };
}

/// Pas de Cloud Function ni d'API externe pour le MVP : le statut ne reflete
/// donc que le succes ou l'echec de l'ouverture de WhatsApp sur l'appareil,
/// pas une confirmation de livraison.
enum StatutMessage { envoye, echec }

/// Document `enseignants/{uid}/messages/{messageId}`.
/// `eleveNom` / `classeNom` sont denormalises : Firestore ne fait pas de
/// jointures, on evite ainsi une lecture supplementaire par ligne d'historique.
class MessageEntry {
  final String id;
  final String eleveId;
  final String eleveNom;
  final String classeId;
  final String classeNom;
  final String contenu;
  final TypeMessage type;
  final StatutMessage statut;
  final String telephoneDestinataire;
  final DateTime dateEnvoi;

  MessageEntry({
    required this.id,
    required this.eleveId,
    required this.eleveNom,
    required this.classeId,
    required this.classeNom,
    required this.contenu,
    required this.type,
    required this.statut,
    required this.telephoneDestinataire,
    required this.dateEnvoi,
  });

  factory MessageEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MessageEntry(
      id: doc.id,
      eleveId: data['eleveId'] as String? ?? '',
      eleveNom: data['eleveNom'] as String? ?? '',
      classeId: data['classeId'] as String? ?? '',
      classeNom: data['classeNom'] as String? ?? '',
      contenu: data['contenu'] as String? ?? '',
      type: TypeMessageWire.fromWire(data['type'] as String? ?? ''),
      statut: (data['statut'] as String?) == 'echec'
          ? StatutMessage.echec
          : StatutMessage.envoye,
      telephoneDestinataire: data['telephoneDestinataire'] as String? ?? '',
      dateEnvoi: (data['dateEnvoi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'eleveId': eleveId,
    'eleveNom': eleveNom,
    'classeId': classeId,
    'classeNom': classeNom,
    'contenu': contenu,
    'type': type.wireName,
    'statut': statut == StatutMessage.echec ? 'echec' : 'envoye',
    'telephoneDestinataire': telephoneDestinataire,
    'dateEnvoi': Timestamp.fromDate(dateEnvoi),
  };
}
