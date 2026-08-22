import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
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
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _emailCtrl.clear();
      _pinCtrl.clear();
      _error = null;
    });
  }

  Future<void> _doLogin() async {
    final app = context.read<AppState>();
    final email = _emailCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = app.tr('login.emailRequired'));
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = app.tr('login.emailInvalid'));
      return;
    }
    if (pin.isEmpty) {
      setState(() => _error = app.tr('login.pinRequired'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.login(email, pin);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.read<AppState>().tr('login.error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForgotPassword() async {
    final app = context.read<AppState>();
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;
    String? error;
    String? success;
    await showDialog<void>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setDialogState) => AlertDialog(
          title: Text(app.tr('login.forgotTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.tr('login.forgotMessage'),
                style: AppText.sans(size: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              if (error != null) ...[
                ErrorBanner(error!),
                const SizedBox(height: 10),
              ],
              if (success != null) ...[
                Text(
                  success!,
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.accentGreenText,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'nom@exemple.com'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: Text(app.tr('common.close')),
            ),
            TextButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (!_emailPattern.hasMatch(email)) {
                        setDialogState(
                          () => error = app.tr('login.emailInvalid'),
                        );
                        return;
                      }
                      setDialogState(() {
                        sending = true;
                        error = null;
                        success = null;
                      });
                      try {
                        await app.resetPassword(email);
                        setDialogState(() {
                          sending = false;
                          success = app.tr('login.forgotSuccess');
                        });
                      } catch (_) {
                        setDialogState(() {
                          sending = false;
                          error = app.tr('login.error');
                        });
                      }
                    },
              child: Text(
                sending
                    ? app.tr('login.forgotSending')
                    : success == null
                    ? app.tr('login.forgotSend')
                    : app.tr('login.forgotResend'),
              ),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_jangalekat_rounded.png',
                          width: 64,
                          height: 64,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jàngalekat',
                          style: AppText.sans(
                            size: 26,
                            weight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.tr('login.subtitle'),
                          style: AppText.sans(
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 14),
                    ],
                    LabeledField(
                      label: app.tr('login.email'),
                      controller: _emailCtrl,
                      hint: 'nom@exemple.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: app.tr('login.pin'),
                      controller: _pinCtrl,
                      hint: '••••••',
                      keyboardType: TextInputType.number,
                      obscure: true,
                      maxLength: 6,
                      fontSize: 20,
                      letterSpacing: 6,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _loading
                          ? app.tr('login.connecting')
                          : app.tr('login.connect'),
                      onPressed: _loading ? null : _doLogin,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _openForgotPassword,
                      child: Text(
                        app.tr('login.forgot'),
                        style: AppText.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.accentGreenText,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetForm();
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            )
                            .then((_) {
                              if (mounted) _resetForm();
                            });
                      },
                      child: Text(
                        app.tr('login.createAccount'),
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
                            active: app.locale == AppLocale.fr,
                            onTap: () => app.setLocale(AppLocale.fr),
                          ),
                          const SizedBox(width: 8),
                          _LangPill(
                            label: 'EN',
                            active: app.locale == AppLocale.en,
                            onTap: () => app.setLocale(AppLocale.en),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
