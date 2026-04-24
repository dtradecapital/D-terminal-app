import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  int _phase = 0;
  final List<String> _words = ["The", "Edge", "Was", "Always", "You."];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

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
    setState(() => _phase = 1); // Canvas in

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = 2); // Logo (if any) sails up - using as placeholder for timing

    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    setState(() => _phase = 3); // Title sweep + shimmer
    _shimmerController.forward();

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _phase = 4); // Tagline rises

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _phase = 5); // Finalize display

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    // Fade out phase
    setState(() => _phase = 6);

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
    _waveController.dispose();
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background & Canvas Layer
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _phase >= 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: CustomPaint(
                  painter: SplashPainter(
                    animationValue: _waveController.value,
                  ),
                ),
              ),
            ),

            // Scanlines
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  painter: ScanlinePainter(),
                ),
              ),
            ),

            // Vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  // D TERMINAL Title
                  _buildShimmeringTitle(),
                  const SizedBox(height: 12),
                  // Tagline
                  _buildTagline(),
                ],
              ),
            ),
          ],
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
                // background-position: 150% center; -> -150% center;
                // We use a linear gradient and slide its stops/transform
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
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10.0,
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

class SplashPainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles = List.generate(70, (index) => Particle());

  SplashPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Radial Background
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.24), // H * 0.38
        radius: 1.4, // size.width * 0.7 approx
        colors: [
          Color(0xFF080614),
          Color(0xFF000000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Chart Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.022)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Particles
    final particlePaint = Paint();
    for (var p in particles) {
      p.update(size, animationValue);
      final currentPos = p.getPosition(size, animationValue);
      final alpha = p.opacity * (0.7 + 0.3 * math.sin(p.twinkle + animationValue * 20));
      particlePaint.color = const Color(0xFFF5C850).withOpacity(alpha.clamp(0, 1));
      canvas.drawCircle(currentPos, p.r, particlePaint);
    }

    // Wave 1 - Deep dark base
    _drawWave(
      canvas, 
      size, 
      animationValue, 
      yOffset: 0.63, 
      amplitude: 26, 
      frequency: 2.8,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF040412).withOpacity(0.97),
          const Color(0xFF000000),
        ],
      ),
      glow: true,
    );

    // Wave 2 - Mid gold tint
    _drawWave(
      canvas, 
      size, 
      animationValue * 0.85, 
      yOffset: 0.73, 
      amplitude: 18, 
      frequency: 3.2,
      phaseOffset: 0.9,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF59E0B).withOpacity(0.09),
          const Color(0xFF000000).withOpacity(0.5),
        ],
      ),
    );

    // Wave 3 - Surface shimmer
    _drawWave(
      canvas, 
      size, 
      animationValue * 1.3, 
      yOffset: 0.81, 
      amplitude: 12, 
      frequency: 4.2,
      phaseOffset: 1.6,
      gradient: LinearGradient(
        colors: [
          const Color(0xFFF59E0B).withOpacity(0.04),
          const Color(0xFFF59E0B).withOpacity(0.04),
        ],
      ),
    );
  }

  void _drawWave(
    Canvas canvas, 
    Size size, 
    double t, {
    required double yOffset,
    required double amplitude,
    required double frequency,
    double phaseOffset = 0,
    required Gradient gradient,
    bool glow = false,
  }) {
    final path = Path();
    path.moveTo(0, size.height);
    
    double crestY(double x) {
      return size.height * yOffset +
        math.sin((x / size.width) * math.pi * frequency + t * 2 * math.pi + phaseOffset) * amplitude +
        math.sin((x / size.width) * math.pi * (frequency * 2) + t * 3.14 + phaseOffset) * (amplitude * 0.4);
    }

    for (double x = 0; x <= size.width; x += 3) {
      path.lineTo(x, crestY(x));
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()..shader = gradient.createShader(Offset.zero & size);
    canvas.drawPath(path, paint);

    if (glow) {
      // Glow Line
      final glowPaint = Paint()
        ..color = const Color(0xFFF59E0B).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      final glowPath = Path();
      glowPath.moveTo(0, crestY(0));
      for (double x = 3; x <= size.width; x += 3) {
        glowPath.lineTo(x, crestY(x));
      }
      canvas.drawPath(glowPath, glowPaint);

      // Bright Crest Line
      final brightPaint = Paint()
        ..color = const Color(0xFFFDE68A).withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(glowPath, brightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) => true;
}

class Particle {
  late double initialX;
  late double initialY;
  late double r;
  late double speed;
  late double drift;
  late double opacity;
  late double twinkle;
  bool initialized = false;

  void update(Size size, double t) {
    if (!initialized) {
      final rand = math.Random();
      initialX = rand.nextDouble() * size.width;
      initialY = rand.nextDouble() * size.height;
      r = rand.nextDouble() * 1.5 + 0.5;
      speed = rand.nextDouble() * 0.15 + 0.05;
      drift = (rand.nextDouble() - 0.5) * 0.1;
      opacity = rand.nextDouble() * 0.4 + 0.1;
      twinkle = rand.nextDouble() * math.pi * 2;
      initialized = true;
    }
  }

  Offset getPosition(Size size, double t) {
    // Calculate current position based on initial position and time
    // t goes from 0..1 over 10 seconds (as defined in Controller)
    double timeFactor = t * 10; 
    double x = (initialX + drift * timeFactor * 100) % size.width;
    double y = (initialY - speed * timeFactor * 200) % size.height;
    if (y < 0) y += size.height;
    return Offset(x, y);
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 1.0;
    
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
