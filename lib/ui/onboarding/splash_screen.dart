import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/chat/chat_screen.dart';
import 'package:ma_water/ui/onboarding/onboarding_screen.dart';

/// The launch screen for "Mā".
///
/// A full-bleed [AppColors.blockNavy] poster — the single dark color block in
/// the otherwise monochrome editorial system. The brand lockup (solid white
/// drop glyph + "مياه" wordmark) and the Arabic tagline render in inverse ink
/// on the navy ground, FLAT (no shadows, no gradients). After a brief settle
/// the screen routes onward.
///
/// In v1 the app always proceeds straight to [ChatScreen] for simplicity, but
/// the [OnboardingScreen] route is kept available (and would be shown on first
/// run once a real "first run" flag is wired up).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Whether this is the user's first launch. When `true` the splash would
  /// route to [OnboardingScreen]; for v1 we always go to [ChatScreen].
  static const bool isFirstRun = false;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // A gentle fade + settle for the brand lockup as the screen appears.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _introController.forward();
    _timer = Timer(const Duration(milliseconds: 1800), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    // v1: always go to the chat. The onboarding route remains available for a
    // future first-run flow (see [SplashScreen.isFirstRun]).
    final Widget next = SplashScreen.isFirstRun
        ? const OnboardingScreen()
        : const ChatScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inverse ink on the navy block.
    const Color onNavy = AppColors.canvas;

    return Scaffold(
      // Full-bleed navy color block — the single dark poster surface.
      backgroundColor: AppColors.blockNavy,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mono uppercase eyebrow — the editorial taxonomy marker.
                Text(
                  'IRAQ WATER LEVELS',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.eyebrow.copyWith(color: onNavy),
                ),
                const SizedBox(height: AppSpacing.lg),
                // White brand lockup: solid drop glyph + "مياه" wordmark.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.water_drop,
                      size: 56,
                      color: onNavy,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'مياه',
                      style: AppTextStyles.displayLg.copyWith(color: onNavy),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'مساعد مستوى المياه في العراق',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLg.copyWith(color: onNavy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
