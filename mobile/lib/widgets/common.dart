import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Pastille "12.5" coloree selon le seuil de reussite.
class AvgPill extends StatelessWidget {
  final double? avg;
  final double fontSize;
  const AvgPill({super.key, required this.avg, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final value = avg;
    final color = value == null
        ? AppColors.textFaint
        : AppColors.avgColor(value);
    final bg = value == null ? AppColors.card : AppColors.avgBg(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value == null ? '—' : value.toStringAsFixed(1),
        style: AppText.sans(
          size: fontSize,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Avatar carre avec initiales, fond vert fonce / texte or (identite visuelle Jangalekat).
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const InitialsAvatar({super.key, required this.initials, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      child: Text(
        initials,
        style: AppText.sans(
          size: size * 0.34,
          weight: FontWeight.w700,
          color: AppColors.brandGold,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.sans(
        size: 11,
        weight: FontWeight.w600,
        color: AppColors.textFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class BackHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const BackHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.sans(size: 19, weight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: AppText.sans(
                        size: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.accentGreen,
    this.foreground = AppColors.accentGreenDarkText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ texte etiquette + carte, reutilise par tous les formulaires/sheets
/// de creation-edition (classe, eleve, matiere, fiche de cours, login,
/// inscription...) : ces ecrans avaient chacun leur propre copie quasi-
/// identique de ce widget. `obscure` ajoute un bouton afficher/masquer
/// (champs PIN) : etat local, d'ou le passage en `StatefulWidget`.
class LabeledField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscure;
  final int? maxLength;
  final double fontSize;
  final double? letterSpacing;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscure = false,
    this.maxLength,
    this.fontSize = 15,
    this.letterSpacing,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
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
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            obscureText: widget.obscure && !_visible,
            maxLength: widget.maxLength,
            style: AppText.sans(
              size: widget.fontSize,
              weight: FontWeight.w600,
              letterSpacing: widget.letterSpacing,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.sans(
                size: widget.fontSize,
                color: AppColors.textFaint,
              ),
              border: InputBorder.none,
              counterText: widget.obscure ? '' : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _visible ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textFaint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _visible = !_visible),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog de confirmation avant suppression, reutilise par tous les ecrans
/// qui suppriment quelque chose (classe, eleve, fiche de cours...) : chacun
/// avait sa propre copie quasi-identique de cet `AlertDialog`.
Future<bool> confirmDelete(
  BuildContext context,
  AppState app, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(false),
          child: Text(app.tr('common.cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(true),
          child: Text(
            app.tr('common.delete'),
            style: TextStyle(color: AppColors.dangerText),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Champ telephone : indicatif pays modifiable (Sénégal +221 par defaut,
/// gere aussi les enseignants/parents a l'etranger) separe du numero local,
/// pour eviter les erreurs de saisie du "+221" (tape deux fois, oublie,
/// mal place...). Les deux `TextEditingController` sont fournis par
/// l'ecran appelant (meme pattern que les autres champs de l'app) ; le
/// numero complet a soumettre se construit avec `combinePhone`.
class PhoneField extends StatelessWidget {
  final TextEditingController codeController;
  final TextEditingController numberController;
  const PhoneField({
    super.key,
    required this.codeController,
    required this.numberController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Text('+', style: AppText.sans(size: 15, weight: FontWeight.w600)),
          SizedBox(
            width: 32,
            child: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppText.sans(size: 15, weight: FontWeight.w600),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(width: 1, height: 22, color: AppColors.cardBorder),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppText.sans(size: 15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '77 000 00 00',
                hintStyle: AppText.sans(size: 15, color: AppColors.textFaint),
                border: InputBorder.none,
                isDense: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// Numero complet a soumettre depuis un `PhoneField`.
String combinePhone(
  TextEditingController codeController,
  TextEditingController numberController,
) {
  final code = codeController.text.trim().isEmpty
      ? '221'
      : codeController.text.trim();
  final number = numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
  return '+$code$number';
}

/// Decoupe un numero stocke (ex. "+221770000000", saisi avant l'ajout du
/// champ indicatif separe) en indicatif + numero local, pour pre-remplir un
/// `PhoneField` en edition. Hypothese : un numero local senegalais fait 9
/// chiffres — heuristique, pas une validation stricte, puisque les numeros
/// stockes avant cette fonctionnalite pouvaient etre saisis dans n'importe
/// quel format.
({String code, String number}) splitPhone(String stored) {
  final digits = stored.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length > 9) {
    return (
      code: digits.substring(0, digits.length - 9),
      number: digits.substring(digits.length - 9),
    );
  }
  return (code: '221', number: digits);
}

/// Libelle du type de message, utilise pour l'historique et les dernieres
/// activites du tableau de bord (memes cles de traduction dans les deux
/// cas, garde ici pour eviter la duplication).
String messageTypeLabel(TypeMessage type, AppState app) => switch (type) {
  TypeMessage.felicitations => app.tr('whatsapp.templateCongrats'),
  TypeMessage.convocation => app.tr('whatsapp.templateSummon'),
  TypeMessage.alerte => app.tr('history.typeAlerte'),
  TypeMessage.groupe => app.tr('history.typeGroupe'),
  TypeMessage.personnalise => app.tr('history.typeMessage'),
};

/// Feuille de details d'un message envoye : destinataire, classe,
/// telephone, date/heure, statut et contenu complet, avec suppression
/// (douce, voir `MessageService.softDelete`). Utilisee depuis l'historique
/// et depuis les "Dernieres activites" du tableau de bord, memes donnees
/// affichees dans les deux cas. `onDeleted` : rappel pour que l'ecran
/// appelant recharge sa liste apres suppression.
void showMessageDetailSheet(
  BuildContext context,
  AppState app,
  MessageEntry message, {
  VoidCallback? onDeleted,
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final dt = message.dateEnvoi;
  final dateHeure =
      '${two(dt.day)}/${two(dt.month)}/${dt.year} · ${two(dt.hour)}:${two(dt.minute)}';

  Future<void> confirmerSuppression(BuildContext sheetContext) async {
    final confirmed = await confirmDelete(
      sheetContext,
      app,
      title: app.tr('history.deleteConfirmTitle'),
      message: app.tr('history.deleteConfirmMessage'),
    );
    if (!confirmed) return;
    try {
      await app.messageService.softDelete(message.id);
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      onDeleted?.call();
    } catch (_) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(SnackBar(content: Text(app.tr('history.deleteError'))));
      }
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 18,
                    color: AppColors.accentGreenText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    messageTypeLabel(message.type, app),
                    style: AppText.sans(size: 17, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailRow(
              label: app.tr('history.detailStudent'),
              value: message.eleveNom,
            ),
            _DetailRow(
              label: app.tr('history.detailClass'),
              value: message.classeNom,
            ),
            _DetailRow(
              label: app.tr('history.detailPhone'),
              value: message.telephoneDestinataire,
            ),
            _DetailRow(label: app.tr('history.detailDate'), value: dateHeure),
            _DetailRow(
              label: app.tr('history.detailStatus'),
              value: message.statut == StatutMessage.echec
                  ? app.tr('history.statusFailed')
                  : app.tr('history.statusSent'),
              valueColor: message.statut == StatutMessage.echec
                  ? AppColors.dangerText
                  : AppColors.accentGreenText,
            ),
            const SizedBox(height: 8),
            Text(
              app.tr('history.detailContent').toUpperCase(),
              style: AppText.sans(
                size: 11,
                weight: FontWeight.w600,
                color: AppColors.textFaint,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message.contenu,
                style: AppText.sans(size: 13.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: app.tr('history.deleteMessage'),
              background: AppColors.dangerBg,
              foreground: AppColors.dangerText,
              onPressed: () => confirmerSuppression(ctx),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppText.sans(size: 12.5, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w600,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: AppText.sans(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.dangerText,
        ),
      ),
    );
  }
}
