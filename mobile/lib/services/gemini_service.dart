import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/fiche_contenu.dart';

/// Erreur volontairement typee (et non une Exception generique) pour que les
/// ecrans puissent afficher directement `e.message` a l'enseignant sans
/// avoir a interpreter un code HTTP ou une exception reseau.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);
  @override
  String toString() => message;
}

/// Appelle l'API Gemini (Google AI Studio) pour generer une fiche de cours
/// structuree. `POST /v1beta/models/{model}:generateContent`.
class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _timeout = Duration(seconds: 45);

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Modele configurable via .env (GEMINI_MODEL), sinon un modele Gemini
  /// recent par defaut.
  String get _model => dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
      ? dotenv.env['GEMINI_MODEL']!.trim()
      : 'gemini-2.5-flash';

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
      throw GeminiException(
        'Clé API Gemini manquante — ajoutez GEMINI_API_KEY dans le fichier .env (voir README).',
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
            Uri.parse('$_baseUrl/$_model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': userPrompt},
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.4,
              },
            }),
          )
          .timeout(_timeout);
    } on SocketException {
      throw GeminiException(
        'Pas de connexion internet — la génération de fiche nécessite une connexion.',
      );
    } on TimeoutException {
      throw GeminiException('Gemini met trop de temps à répondre, réessayez.');
    } on http.ClientException {
      throw GeminiException('Impossible de contacter le serveur Gemini.');
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw GeminiException(
        'Clé API Gemini invalide ou expirée : ${_extractErrorMessage(response.bodyBytes) ?? 'vérifiez GEMINI_API_KEY.'}',
      );
    }
    if (response.statusCode == 403) {
      throw GeminiException(
        'Accès refusé par Gemini : ${_extractErrorMessage(response.bodyBytes) ?? 'vérifiez les autorisations de la clé sur aistudio.google.com.'}',
      );
    }
    if (response.statusCode == 429) {
      throw GeminiException('Quota Gemini atteint — réessayez plus tard.');
    }
    if (response.statusCode >= 500) {
      throw GeminiException('Le serveur Gemini est indisponible, réessayez.');
    }
    if (response.statusCode != 200) {
      final detail = _extractErrorMessage(response.bodyBytes);
      throw GeminiException(
        detail != null
            ? 'Échec de la génération : $detail'
            : 'Échec de la génération (code ${response.statusCode}).',
      );
    }

    return _parseResponse(response.bodyBytes);
  }

  /// Gemini renvoie les erreurs sous la forme `{"error":{"message":"..."}}` :
  /// on remonte ce message tel quel a l'enseignant plutot qu'un code HTTP nu.
  String? _extractErrorMessage(List<int> bodyBytes) {
    try {
      final decoded =
          jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt(String langue) {
    final langueTexte = langue == 'wolof' ? 'wolof' : 'français';
    return '''
Tu es un assistant pedagogique pour des enseignants du primaire/secondaire en Afrique de l'Ouest.
Tu generes des fiches de cours claires, concretes et directement utilisables en classe.
Reponds UNIQUEMENT en $langueTexte, et UNIQUEMENT avec un objet JSON valide, sans texte autour, avec exactement ces cles (toutes en texte libre, plusieurs phrases ou une liste a puces sous forme de texte).
N'utilise AUCUN symbole de mise en forme Markdown : pas de **gras**, pas de _italique_, pas de #titres, pas de `code`. Texte brut uniquement. Pour une liste, utilise des lignes commencant par "- " ou "1. ", sans aucun autre symbole.
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
      final content =
          decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      final ficheJson = jsonDecode(content) as Map<String, dynamic>;
      return FicheContenu.fromJson(ficheJson);
    } catch (_) {
      throw GeminiException('Réponse de Gemini illisible, réessayez.');
    }
  }
}
