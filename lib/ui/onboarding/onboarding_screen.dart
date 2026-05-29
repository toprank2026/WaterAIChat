import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/chat/chat_screen.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// First-run explainer for "Mā".
///
/// A clean white screen led by a Gemini-style gradient sparkle header, three
/// feature bullets, a faux on-device model "download" progress bar (no real
/// download happens in v1), and an animated-gradient "ابدأ" button that opens
/// [ChatScreen].
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
              const Center(child: _GradientHeader()),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GradientText(
                  'مرحبًا بك في مياه',
                  style: AppTextStyles.displayMd,
                  gradient: AppColors.geminiGradient,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'مساعدك الذكي لمتابعة مستويات المياه في العراق',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.slate),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _FeatureRow(
                icon: Icons.chat_bubble_outline,
                text: 'اسأل بالعربية',
              ),
              const SizedBox(height: AppSpacing.md),
              const _FeatureRow(
                icon: Icons.insert_chart_outlined,
                text: 'احصل على رسوم بيانية تفاعلية',
              ),
              const SizedBox(height: AppSpacing.md),
              const _FeatureRow(
                icon: Icons.cloud_off_outlined,
                text: 'يعمل دون إنترنت',
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

/// The hero header: a Gemini-style gradient sparkle inside a softly tinted,
/// rounded badge.
class _GradientHeader extends StatelessWidget {
  const _GradientHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl + AppSpacing.lg,
      height: AppSpacing.xxl + AppSpacing.lg,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Center(
        child: GradientIcon(
          icon: Icons.auto_awesome,
          size: AppSpacing.xl,
          gradient: AppColors.geminiGradient,
        ),
      ),
    );
  }
}

/// A single feature bullet: a tinted leading icon followed by Arabic copy.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.teal, size: AppSpacing.lg),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.titleMd,
          ),
        ),
      ],
    );
  }
}

/// The faux model-download status: a label plus a [LinearProgressIndicator].
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
              color: ready ? AppColors.ok : AppColors.slate,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                ready ? 'النموذج جاهز للعمل' : 'جارٍ تجهيز النموذج على جهازك…',
                style: AppTextStyles.caption.copyWith(
                  color: ready ? AppColors.ok : AppColors.slate,
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
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
        ),
      ],
    );
  }
}

/// Animated-gradient call-to-action button. Disabled (dimmed) until the model
/// is ready.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.pill);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedGradient(
          colors: AppColors.geminiColors,
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
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
                    style:
                        AppTextStyles.titleLg.copyWith(color: AppColors.card),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
