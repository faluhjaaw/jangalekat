import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// Ecran de creation de compte, non present dans les maquettes mais
/// necessaire pour permettre a un enseignant de s'inscrire avant sa
/// premiere connexion (Auth: inscription/connexion, cf. cahier des charges).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomCtrl = TextEditingController();
  final _telCodeCtrl = TextEditingController(text: '221');
  final _telNumberCtrl = TextEditingController();
  final _ecoleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _iaCtrl = TextEditingController();
  final _iefCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCodeCtrl.dispose();
    _telNumberCtrl.dispose();
    _ecoleCtrl.dispose();
    _emailCtrl.dispose();
    _iaCtrl.dispose();
    _iefCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    final app = context.read<AppState>();
    final nom = _nomCtrl.text.trim();
    final phoneDigits = _telNumberCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final pin = _pinCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _error = app.tr('register.fullNameRequired'));
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = app.tr('register.emailRequired'));
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = app.tr('register.emailInvalid'));
      return;
    }
    if (pin.isEmpty) {
      setState(() => _error = app.tr('register.pinRequired'));
      return;
    }
    if (pin.length < 6) {
      setState(() => _error = app.tr('register.pinTooShort'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.register(
        nom: nom,
        email: email,
        pin: pin,
        ecole: _ecoleCtrl.text.trim().isEmpty ? null : _ecoleCtrl.text.trim(),
        telephone: phoneDigits.isEmpty
            ? null
            : combinePhone(_telCodeCtrl, _telNumberCtrl),
        ia: _iaCtrl.text.trim().isEmpty ? null : _iaCtrl.text.trim(),
        ief: _iefCtrl.text.trim().isEmpty ? null : _iefCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = app.tr('register.error'));
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackHeader(
                title: app.tr('register.title'),
                subtitle: app.tr('login.subtitle'),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ErrorBanner(_error!),
                ),
              ],
              LabeledField(
                label: app.tr('register.fullName'),
                controller: _nomCtrl,
                hint: 'Mme Diop',
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: app.tr('register.school'),
                controller: _ecoleCtrl,
                hint: 'École de Marché Sor',
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: app.tr('register.email'),
                controller: _emailCtrl,
                hint: 'diop@exemple.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      label: app.tr('register.ia'),
                      controller: _iaCtrl,
                      hint: 'Dakar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: app.tr('register.ief'),
                      controller: _iefCtrl,
                      hint: 'Dakar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                app.tr('register.phone').toUpperCase(),
                style: AppText.sans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: AppColors.textFaint,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 7),
              PhoneField(
                codeController: _telCodeCtrl,
                numberController: _telNumberCtrl,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: app.tr('login.pin'),
                controller: _pinCtrl,
                hint: app.tr('register.pinHint'),
                keyboardType: TextInputType.number,
                obscure: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading
                    ? app.tr('register.creating')
                    : app.tr('register.createButton'),
                onPressed: _loading ? null : _doRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

