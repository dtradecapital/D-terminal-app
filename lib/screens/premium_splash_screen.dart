import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  int _phase = 0;
  final List<String> _words = ["The", "Edge", "Was", "Always", "You."];

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _startPhaseTimeline();
  }

  void _startPhaseTimeline() async {
    // Phase 0: Initial (Black)
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _phase = 1);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = 2);

    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    setState(() => _phase = 3); // Title sweep + shimmer
    _shimmerController.forward();

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _phase = 4); // Tagline rises

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _phase = 5);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _phase = 6); // Fade out

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedOpacity(
        opacity: _phase >= 6 ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.ease,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              _buildShimmeringTitle(),
              const SizedBox(height: 12),
              _buildTagline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmeringTitle() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.only(top: _phase >= 3 ? 0 : 20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _phase >= 3 ? 1.0 : 0.0,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                final double slideValue = _shimmerController.value;
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF92400E),
                    Color(0xFFF59E0B),
                    Color(0xFFFEF3C7),
                    Color(0xFFF59E0B),
                    Color(0xFF92400E),
                  ],
                  stops: [
                    (0.0 + (1.0 - slideValue * 2)).clamp(0.0, 1.0),
                    (0.28 + (1.0 - slideValue * 2)).clamp(0.0, 1.0),
                    (0.5 + (1.0 - slideValue * 2)).clamp(0.0, 1.0),
                    (0.72 + (1.0 - slideValue * 2)).clamp(0.0, 1.0),
                    (1.0 + (1.0 - slideValue * 2)).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'D TERMINAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: List.generate(_words.length, (index) {
        return AnimatedOpacity(
          opacity: _phase >= 4 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: const Interval(0.0, 1.0, curve: Curves.ease),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0,
              _phase >= 4 ? 0 : 32,
              0,
            ),
            child: Text(
              _words[index],
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: index == 4 ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      }),
    );
  }
}
