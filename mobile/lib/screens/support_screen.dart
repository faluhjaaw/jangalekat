import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// Numero/adresse de support a but demo (a remplacer par les vrais canaux
/// officiels de l'equipe Jangalekat avant mise en production).
const _kSupportPhone = '221770000000';
const _kSupportEmail = 'support@jangalekat.app';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _error;

  Future<void> _open(Uri uri) async {
    final app = context.read<AppState>();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      setState(() => _error = app.tr('support.openError'));
    }
  }

  void _openWhatsapp() => _open(Uri.https('wa.me', '/$_kSupportPhone'));

  void _openEmail() => _open(Uri(scheme: 'mailto', path: _kSupportEmail));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final faqs = [
      (app.tr('support.faq1Q'), app.tr('support.faq1A')),
      (app.tr('support.faq2Q'), app.tr('support.faq2A')),
      (app.tr('support.faq3Q'), app.tr('support.faq3A')),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackHeader(title: app.tr('support.title')),
              const SizedBox(height: 12),
              if (_error != null) ...[
                ErrorBanner(_error!),
                const SizedBox(height: 12),
              ],
              SectionLabel(app.tr('support.faqTitle')),
              const SizedBox(height: 10),
              for (final faq in faqs) ...[
                _FaqCard(question: faq.$1, answer: faq.$2),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              SectionLabel(app.tr('support.contactTitle')),
              const SizedBox(height: 10),
              PrimaryButton(
                label: app.tr('support.contactWhatsapp'),
                onPressed: _openWhatsapp,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: app.tr('support.contactEmail'),
                background: AppColors.card,
                foreground: AppColors.textDark,
                onPressed: _openEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppText.sans(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
