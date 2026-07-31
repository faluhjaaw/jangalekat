import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String _lang = 'FR';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().login(
        _phoneCtrl.text.trim(),
        _pinCtrl.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Impossible de se connecter');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'J',
                      style: AppText.mono(
                        size: 28,
                        weight: FontWeight.w700,
                        color: AppColors.brandGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jàngalekat',
                    style: AppText.mono(
                      size: 26,
                      weight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Espace enseignant',
                    style: AppText.sans(size: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (_error != null) ...[
                ErrorBanner(_error!),
                const SizedBox(height: 14),
              ],
              _FieldLabel('Numéro de téléphone'),
              const SizedBox(height: 7),
              _LoginField(
                controller: _phoneCtrl,
                hint: '+221 77 000 00 00',
                keyboardType: TextInputType.phone,
                monoSize: 16,
              ),
              const SizedBox(height: 18),
              _FieldLabel('Code PIN'),
              const SizedBox(height: 7),
              _LoginField(
                controller: _pinCtrl,
                hint: '••••••',
                keyboardType: TextInputType.number,
                obscure: true,
                monoSize: 20,
                maxLength: 6,
                letterSpacing: 6,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading ? 'Connexion...' : 'Se connecter',
                onPressed: _loading ? null : _doLogin,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Code oublié ?',
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.accentGreenText,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: Text(
                  'Créer un compte enseignant',
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LangPill(
                      label: 'FR',
                      active: _lang == 'FR',
                      onTap: () => setState(() => _lang = 'FR'),
                    ),
                    const SizedBox(width: 8),
                    _LangPill(
                      label: 'Wolof',
                      active: _lang == 'Wolof',
                      onTap: () => setState(() => _lang = 'Wolof'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: AppText.sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.textFaint,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final double monoSize;
  final int? maxLength;
  final double? letterSpacing;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.obscure = false,
    this.monoSize = 16,
    this.maxLength,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLength: maxLength,
        style: AppText.mono(
          size: monoSize,
          weight: FontWeight.w600,
          letterSpacing: letterSpacing,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.mono(
            size: monoSize,
            weight: FontWeight.w600,
            color: AppColors.textFaint,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brandDark : AppColors.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 12,
            weight: FontWeight.w600,
            color: active ? AppColors.textOnDark : AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}
