import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/design/color_block.dart';
import 'package:ma_water/ui/chat/chat_screen.dart';

/// First-run explainer for "Mā".
///
/// A clean white editorial canvas: a small mono uppercase eyebrow over an ink
/// display title, three oversized pastel **feature blocks** (lime / cream /
/// lilac — the system's signature color-block depth device), a flat hairline
/// faux on-device model "download" note (no real download happens in v1), and
/// a black **pill** "ابدأ" CTA that opens [ChatScreen].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Drives the faux "model download" indicator from 0 → 1.
  double _progress = 0;
  Timer? _ticker;

  bool get _ready => _progress >= 1;

  @override
  void initState() {
    super.initState();
    // Simulate a short, smooth "download" that always completes.
    _ticker = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + 0.08).clamp(0.0, 1.0);
      });
      if (_progress >= 1) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Mono uppercase eyebrow — taxonomy label above the title.
              Text(
                'مياه · MĀ',
                textAlign: TextAlign.start,
                style: AppTextStyles.eyebrow,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'مرحبًا بك في مياه',
                textAlign: TextAlign.start,
                style: AppTextStyles.displayMd,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'مساعدك الذكي لمتابعة مستويات المياه في العراق',
                textAlign: TextAlign.start,
                style: AppTextStyles.bodyLg,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _FeatureRow(
                icon: Icons.chat_bubble_outline,
                text: 'اسأل بالعربية',
                color: AppColors.blockLime,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _FeatureRow(
                icon: Icons.insert_chart_outlined,
                text: 'احصل على رسوم بيانية تفاعلية',
                color: AppColors.blockCream,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _FeatureRow(
                icon: Icons.cloud_off_outlined,
                text: 'يعمل دون إنترنت',
                color: AppColors.blockLilac,
              ),
              const Spacer(),
              _DownloadNote(progress: _progress, ready: _ready),
              const SizedBox(height: AppSpacing.lg),
              _StartButton(enabled: _ready, onPressed: _start),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single feature bullet rendered as a flat **pastel color block** (the
/// system's depth device): a solid-ink leading icon followed by Arabic copy on
/// a saturated panel. No shadow, no gradient — one [AppColors.block*] per row.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    this.color = AppColors.blockLime,
  });

  final IconData icon;
  final String text;

  /// The pastel panel background. Use an [AppColors.block*] token.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColorBlock(
      color: color,
      radius: AppRadius.lg,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.titleMd,
            ),
          ),
        ],
      ),
    );
  }
}

/// The faux model-download status: a small status row plus a flat hairline
/// progress track (ink fill on a hairline ground — no gradient, no shadow).
class _DownloadNote extends StatelessWidget {
  const _DownloadNote({required this.progress, required this.ready});

  final double progress;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              ready ? Icons.check_circle_outline : Icons.download_outlined,
              size: AppSpacing.md,
              color: ready ? AppColors.ok : AppColors.ink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                ready ? 'النموذج جاهز للعمل' : 'جارٍ تجهيز النموذج على جهازك…',
                style: AppTextStyles.caption.copyWith(
                  color: ready ? AppColors.ok : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppSpacing.xs,
            backgroundColor: AppColors.hairline,
            valueColor: AlwaysStoppedAnimation<Color>(
              ready ? AppColors.ok : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Black **pill** call-to-action (primary CTA = ink fill + white text).
/// Dimmed and inert until the model is ready.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.pill);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: AppColors.ink,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.md,
            ),
            child: Center(
              child: Text(
                'ابدأ',
                style: AppTextStyles.titleLg.copyWith(color: AppColors.canvas),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
