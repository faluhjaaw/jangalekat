import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/fiche_contenu.dart';

/// Erreur volontairement typee (et non une Exception generique) pour que les
/// ecrans puissent afficher directement `e.message` a l'enseignant sans
/// avoir a interpreter un code HTTP ou une exception reseau.
class GrokException implements Exception {
  final String message;
  GrokException(this.message);
  @override
  String toString() => message;
}

/// Appelle l'API Grok (xAI) pour generer une fiche de cours structuree.
/// Compatible format OpenAI : `POST /v1/chat/completions` avec `messages`.
class GrokService {
  static const _endpoint = 'https://api.x.ai/v1/chat/completions';
  static const _timeout = Duration(seconds: 45);

  String get _apiKey => dotenv.env['XAI_API_KEY'] ?? '';

  /// Modele configurable via .env (GROK_MODEL), sinon un modele Grok recent
  /// par defaut.
  String get _model => dotenv.env['GROK_MODEL']?.trim().isNotEmpty == true
      ? dotenv.env['GROK_MODEL']!.trim()
      : 'grok-4';

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<FicheContenu> genererFiche({
    required String matiere,
    required String niveau,
    required String theme,
    String? objectifsSaisis,
    String? duree,
    required String langue,
  }) async {
    if (!isConfigured) {
      throw GrokException(
        'Clé API xAI manquante — ajoutez XAI_API_KEY dans le fichier .env (voir README).',
      );
    }

    final systemPrompt = _buildSystemPrompt(langue);
    final userPrompt = _buildUserPrompt(
      matiere: matiere,
      niveau: niveau,
      theme: theme,
      objectifsSaisis: objectifsSaisis,
      duree: duree,
      langue: langue,
    );

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0.4,
            }),
          )
          .timeout(_timeout);
    } on SocketException {
      throw GrokException(
        'Pas de connexion internet — la génération de fiche nécessite une connexion.',
      );
    } on TimeoutException {
      throw GrokException('Grok met trop de temps à répondre, réessayez.');
    } on http.ClientException {
      throw GrokException('Impossible de contacter le serveur Grok.');
    }

    if (response.statusCode == 401) {
      throw GrokException('Clé API xAI invalide ou expirée.');
    }
    if (response.statusCode == 403) {
      throw GrokException(
        'Accès refusé par xAI : ${_extractErrorMessage(response.bodyBytes) ?? 'vérifiez les crédits/licence du compte sur console.x.ai.'}',
      );
    }
    if (response.statusCode == 429) {
      throw GrokException('Quota Grok atteint — réessayez plus tard.');
    }
    if (response.statusCode >= 500) {
      throw GrokException('Le serveur Grok est indisponible, réessayez.');
    }
    if (response.statusCode != 200) {
      final detail = _extractErrorMessage(response.bodyBytes);
      throw GrokException(
        detail != null
            ? 'Échec de la génération : $detail'
            : 'Échec de la génération (code ${response.statusCode}).',
      );
    }

    return _parseResponse(response.bodyBytes);
  }

  /// xAI renvoie les erreurs sous la forme `{"code":"...","error":"message"}` :
  /// on remonte ce message tel quel a l'enseignant plutot qu'un code HTTP nu.
  String? _extractErrorMessage(List<int> bodyBytes) {
    try {
      final decoded =
          jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
      return decoded['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt(String langue) {
    final langueTexte = langue == 'wolof' ? 'wolof' : 'français';
    return '''
Tu es un assistant pedagogique pour des enseignants du primaire/secondaire en Afrique de l'Ouest.
Tu generes des fiches de cours claires, concretes et directement utilisables en classe.
Reponds UNIQUEMENT en $langueTexte, et UNIQUEMENT avec un objet JSON valide, sans texte autour, avec exactement ces cles (toutes en texte libre, plusieurs phrases ou une liste a puces sous forme de texte) :
{
  "objectifs": "objectifs pedagogiques de la seance",
  "prerequis": "connaissances/notions que les eleves doivent deja maitriser",
  "deroulement": "plan de la seance etape par etape, avec une estimation du temps par etape",
  "activites": "activites concretes proposees aux eleves",
  "evaluation": "comment verifier que les eleves ont compris (question, exercice, observation)",
  "resume": "resume en 2-3 phrases de la fiche, pour un apercu rapide"
}
''';
  }

  String _buildUserPrompt({
    required String matiere,
    required String niveau,
    required String theme,
    String? objectifsSaisis,
    String? duree,
    required String langue,
  }) {
    final buffer = StringBuffer()
      ..writeln('Matière : $matiere')
      ..writeln('Niveau / classe : $niveau')
      ..writeln('Thème du cours : $theme');
    if (objectifsSaisis != null && objectifsSaisis.trim().isNotEmpty) {
      buffer.writeln(
        'Objectifs pédagogiques souhaités par l\'enseignant : ${objectifsSaisis.trim()}',
      );
    }
    if (duree != null && duree.trim().isNotEmpty) {
      buffer.writeln('Durée prévue de la séance : ${duree.trim()}');
    }
    buffer.write('Génère la fiche de cours au format JSON demandé.');
    return buffer.toString();
  }

  FicheContenu _parseResponse(List<int> bodyBytes) {
    try {
      final decoded =
          jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;
      final ficheJson = jsonDecode(content) as Map<String, dynamic>;
      return FicheContenu.fromJson(ficheJson);
    } catch (_) {
      throw GrokException('Réponse de Grok illisible, réessayez.');
    }
  }
}
