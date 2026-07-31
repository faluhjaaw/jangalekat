import 'package:flutter/material.dart';

import '../models/fiche_contenu.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// Affichage brut de la fiche generee (etape 1 : prouver que l'appel Grok
/// fonctionne bout en bout). Enregistrer/Modifier/Partager/Historique
/// arrivent dans une prochaine etape.
class FicheResultScreen extends StatelessWidget {
  final String matiere;
  final String niveau;
  final String theme;
  final String langue;
  final FicheContenu contenu;

  const FicheResultScreen({
    super.key,
    required this.matiere,
    required this.niveau,
    required this.theme,
    required this.langue,
    required this.contenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            BackHeader(title: theme, subtitle: '$matiere · $niveau'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    label: 'Résumé',
                    texte: contenu.resume,
                    accent: true,
                  ),
                  _Section(label: 'Objectifs', texte: contenu.objectifs),
                  _Section(label: 'Prérequis', texte: contenu.prerequis),
                  _Section(label: 'Déroulement', texte: contenu.deroulement),
                  _Section(label: 'Activités', texte: contenu.activites),
                  _Section(label: 'Évaluation', texte: contenu.evaluation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String texte;
  final bool accent;
  const _Section({
    required this.label,
    required this.texte,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentGreenBg : AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 8),
          Text(
            texte.isEmpty ? '—' : texte,
            style: AppText.sans(size: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
