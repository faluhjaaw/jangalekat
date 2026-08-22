import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _messageCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = context.read<AppState>();
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      setState(() => _error = app.tr('recommendations.empty'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.recommendationService.envoyer(message);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _messageCtrl.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _error = app.tr('recommendations.error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackHeader(title: app.tr('recommendations.title')),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  app.tr('recommendations.subtitle'),
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(_error!),
                const SizedBox(height: 12),
              ],
              if (_sent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreenBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    app.tr('recommendations.sent'),
                    style: AppText.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.accentGreenText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: 6,
                  maxLength: 500,
                  style: AppText.sans(size: 14, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: app.tr('recommendations.hint'),
                    hintStyle: AppText.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.textFaint,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _loading
                    ? app.tr('recommendations.sending')
                    : app.tr('recommendations.send'),
                onPressed: _loading ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
