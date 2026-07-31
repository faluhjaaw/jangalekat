import 'package:flutter/material.dart';

import '../services/grok_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'fiche_result_screen.dart';

/// Formulaire de generation d'une fiche de cours via Grok (xAI).
/// La fiche n'est pas liee a une classe existante : l'enseignant saisit
/// matiere/niveau librement, une fiche peut servir a plusieurs classes.
class FicheFormScreen extends StatefulWidget {
  /// true quand l'ecran est un onglet de la barre de navigation (pas de
  /// bouton retour, entete plein comme Classes/Historique) ; false quand il
  /// est pousse par-dessus un autre ecran (ex. action rapide du tableau de
  /// bord), avec un BackHeader classique.
  final bool embedded;

  const FicheFormScreen({super.key, this.embedded = false});

  @override
  State<FicheFormScreen> createState() => _FicheFormScreenState();
}

class _FicheFormScreenState extends State<FicheFormScreen> {
  final _grokService = GrokService();

  final _matiereCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _themeCtrl = TextEditingController();
  final _objectifsCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  String _langue = 'fr';

  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _matiereCtrl.dispose();
    _niveauCtrl.dispose();
    _themeCtrl.dispose();
    _objectifsCtrl.dispose();
    _dureeCtrl.dispose();
    super.dispose();
  }

  bool get _formValide =>
      _matiereCtrl.text.trim().isNotEmpty &&
      _niveauCtrl.text.trim().isNotEmpty &&
      _themeCtrl.text.trim().isNotEmpty;

  Future<void> _generer() async {
    if (!_formValide) {
      setState(() => _error = 'Matière, niveau et thème sont obligatoires.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final contenu = await _grokService.genererFiche(
        matiere: _matiereCtrl.text.trim(),
        niveau: _niveauCtrl.text.trim(),
        theme: _themeCtrl.text.trim(),
        objectifsSaisis: _objectifsCtrl.text.trim(),
        duree: _dureeCtrl.text.trim(),
        langue: _langue,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FicheResultScreen(
            matiere: _matiereCtrl.text.trim(),
            niveau: _niveauCtrl.text.trim(),
            theme: _themeCtrl.text.trim(),
            langue: _langue,
            contenu: contenu,
          ),
        ),
      );
    } on GrokException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erreur inattendue pendant la génération.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fiches de cours',
                      style: AppText.sans(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Générées par IA (Grok)',
                      style: AppText.sans(size: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              const BackHeader(
                title: 'Fiche de cours',
                subtitle: 'Générée par IA (Grok)',
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    ErrorBanner(_error!),
                    const SizedBox(height: 14),
                  ],
                  _FormField(
                    label: 'Matière',
                    hint: 'Mathématiques',
                    controller: _matiereCtrl,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    label: 'Niveau / classe',
                    hint: 'CM2',
                    controller: _niveauCtrl,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    label: 'Thème du cours',
                    hint: 'La division euclidienne',
                    controller: _themeCtrl,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    label: 'Objectifs pédagogiques (optionnel)',
                    hint: 'Ce que les élèves doivent savoir faire à la fin',
                    controller: _objectifsCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    label: 'Durée prévue (optionnel)',
                    hint: '45 minutes',
                    controller: _dureeCtrl,
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Langue de la fiche'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _LangueButton(
                          label: 'Français',
                          active: _langue == 'fr',
                          onTap: () => setState(() => _langue = 'fr'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LangueButton(
                          label: 'Wolof',
                          active: _langue == 'wolof',
                          onTap: () => setState(() => _langue = 'wolof'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _generating ? 'Génération en cours...' : 'Générer',
                    onPressed: _generating ? null : _generer,
                  ),
                  if (_generating)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGreenText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.sans(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.textFaint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppText.sans(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.sans(size: 15, color: AppColors.textFaint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LangueButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangueButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.brandDark : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 13,
            weight: FontWeight.w700,
            color: active ? AppColors.textOnDark : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
