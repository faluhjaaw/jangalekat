import 'package:flutter/material.dart';
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
        style: AppText.mono(
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
        style: AppText.mono(
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
  const BackHeader({super.key, required this.title, this.subtitle});

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
              child: const Icon(
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
            Text(
              label,
              style: AppText.sans(
                size: 14.5,
                weight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
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
