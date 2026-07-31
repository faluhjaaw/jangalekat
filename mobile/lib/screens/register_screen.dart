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
  final _telCtrl = TextEditingController();
  final _ecoleCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _doRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().register(
        nom: _nomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        pin: _pinCtrl.text.trim(),
        ecole: _ecoleCtrl.text.trim().isEmpty ? null : _ecoleCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Impossible de créer le compte');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackHeader(
                title: 'Créer un compte',
                subtitle: 'Espace enseignant',
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ErrorBanner(_error!),
                ),
              ],
              _Field(
                label: 'Nom complet',
                controller: _nomCtrl,
                hint: 'Mme Diop',
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'École (optionnel)',
                controller: _ecoleCtrl,
                hint: 'École de Marché Sor',
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Téléphone',
                controller: _telCtrl,
                hint: '+221 77 000 00 00',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Code PIN',
                controller: _pinCtrl,
                hint: '6 chiffres minimum',
                keyboardType: TextInputType.number,
                obscure: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading ? 'Création...' : 'Créer mon compte',
                onPressed: _loading ? null : _doRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
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
            keyboardType: keyboardType,
            obscureText: obscure,
            style: AppText.sans(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.sans(
                size: 15,
                weight: FontWeight.w500,
                color: AppColors.textFaint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
