import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_models.dart';

/// Acces Firestore pour `enseignants/{uid}/messages` (historique des envois
/// WhatsApp). Collection a plat (pas sous chaque eleve) pour permettre une
/// seule requete "historique complet" triee par date, cf. ecran Historique.
class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  MessageService(this.uid);

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('enseignants').doc(uid).collection('messages');

  Future<MessageEntry> enregistrer({
    required String eleveId,
    required String eleveNom,
    required String classeId,
    required String classeNom,
    required String contenu,
    required TypeMessage type,
    required StatutMessage statut,
    required String telephoneDestinataire,
  }) async {
    final data = {
      'eleveId': eleveId,
      'eleveNom': eleveNom,
      'classeId': classeId,
      'classeNom': classeNom,
      'contenu': contenu,
      'type': type.wireName,
      'statut': statut == StatutMessage.echec ? 'echec' : 'envoye',
      'telephoneDestinataire': telephoneDestinataire,
      'dateEnvoi': Timestamp.now(),
    };
    final ref = await _messages.add(data);
    final doc = await ref.get();
    return MessageEntry.fromDoc(doc);
  }

  Future<List<MessageEntry>> historique({int limit = 100}) async {
    final snap = await _messages
        .orderBy('dateEnvoi', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(MessageEntry.fromDoc).toList();
  }

  /// Filtre cote client plutot qu'une requete `where` + `orderBy` combinee :
  /// evite d'avoir a declarer un index compose Firestore pour un historique
  /// par eleve qui reste de toute facon petit par enseignant.
  Future<List<MessageEntry>> historiqueEleve(String eleveId) async {
    final tout = await historique();
    return tout.where((m) => m.eleveId == eleveId).toList();
  }
}
