import 'package:flutter/material.dart';
import 'package:mobile/main.dart'; // gives access to AppEntry
import 'package:mobile/core/services/biometric_service.dart';
import 'package:mobile/core/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static bool alreadyShown = false;


  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _line;
  late final Animation<double> _shift;
  late final Animation<double> _textFade;

  TweenSequenceItem<double> _step(double from, double to, double weight) {
    return TweenSequenceItem(
      tween: Tween(
        begin: from,
        end: to,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: weight,
    );
  }

  // One heartbeat: "lub-dub"
  List<TweenSequenceItem<double>> _beat() => [
    _step(1.0, 1.22, 4),
    _step(1.22, 1.0, 4),
    _step(1.0, 1.12, 3),
    _step(1.12, 1.0, 4),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _scale = TweenSequence<double>([
      // 1. Zoom in
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      // 2. Zoom out
      _step(1.5, 1.0, 12),
      // 3. Three heartbeats while the line is drawn
      ..._beat(),
      _step(1.0, 1.0, 3),
      ..._beat(),
      _step(1.0, 1.0, 3),
      ..._beat(),
      // hold
      _step(1.0, 1.0, 15),
    ]).animate(_controller);

    // The ECG line starts after the zoom in/out is finished
    _line = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.85),
    );

    // The heart slides to the left just as the ECG line starts
    _shift = Tween<double>(begin: 0, end: -70).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.45, curve: Curves.easeInOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
    );

    _controller.forward().whenComplete(_goNext);
  }

         Future<void> _goNext() async {
    if (!mounted) return;
    SplashPage.alreadyShown = true;

    try {
      final bio = BiometricService();
      if (await bio.isEnabled()) {
        if (await bio.authenticate()) {
          final creds = await bio.readCredentials();
          if (creds != null) {
            try {
              // Silent login: fresh token, role and name are saved again
              await AuthService.login(
                creds['identifiant']!,
                creds['mot_de_passe']!,
              );
            } catch (_) {
              // Password changed, account disabled, server unreachable...
              await AuthService.logout();
            }
          }
        } else {
          // Cancelled or failed: never reuse the saved session
          await AuthService.logout();
        }
      }
    } catch (_) {
      // Fingerprint unavailable (Chrome...): continue normally
    }

    if (!mounted) return;
    _fadeTo(const AppEntry());
  }
  void _fadeTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF38BDF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final s = _scale.value;
                final dx = _shift.value;
                return SizedBox(
                  width: double.infinity,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ECG line, anchored to the heart's current position
                      CustomPaint(
                        size: Size.infinite,
                        painter: _EcgPainter(_line.value, dx),
                      ),
                      // The heart, sliding left (drawn on top of the line)
                      Transform.translate(
                        offset: Offset(dx, 0),
                        child: Container(
                          width: 170,
                          height: 170,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 50 * s,
                                spreadRadius: 12 * s,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: s,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 130,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textFade,
              child: const Column(
                children: [
                  Text(
                    'SepsisCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Votre santé, notre priorité',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the heartbeat line coming out of the right side of the heart.
class _EcgPainter extends CustomPainter {
  final double progress; // 0 -> 1
  final double shiftX; // how far the heart moved (negative = left)
  _EcgPainter(this.progress, this.shiftX);

  Path _buildPath(double startX, double endX) {
    final path = Path()..moveTo(startX, 0);
    double x = startX;

    while (x < endX) {
      path.lineTo(x + 20, 0);
      path.quadraticBezierTo(x + 30, -10, x + 40, 0); // P wave
      path.lineTo(x + 50, 0);
      path.lineTo(x + 56, 8); // Q
      path.lineTo(x + 66, -60); // R (big spike)
      path.lineTo(x + 78, 32); // S
      path.lineTo(x + 86, 0);
      path.lineTo(x + 100, 0);
      path.quadraticBezierTo(x + 112, -16, x + 124, 0); // T wave
      x += 135;
    }
    path.lineTo(endX, 0);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Starts behind the heart, so it seems to come out of it
    const startX = 50.0;
    // The origin moves with the heart, so the line must run a bit further
    final endX = size.width / 2 - shiftX;

    final path = _buildPath(startX, endX);
    final metric = path.computeMetrics().first;
    final length = metric.length * progress;
    if (length <= 0) return;

    final drawn = metric.extractPath(0, length);
    final tip = metric.getTangentForOffset(length)!.position;

    // The line fades out toward the right edge of the screen
    final shader = LinearGradient(
      colors: [Colors.white, Colors.white, Colors.white.withValues(alpha: 0.1)],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTRB(startX, -60, endX, 60));

    final linePaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final dotPaint = Paint()..color = Colors.white;

    canvas.save();
    // Origin follows the heart as it slides left
    canvas.translate(size.width / 2 + shiftX, size.height / 2);

    canvas.drawPath(drawn, glowPaint);
    canvas.drawPath(drawn, linePaint);
    if (progress < 1) canvas.drawCircle(tip, 4.5, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) =>
      old.progress != progress || old.shiftX != shiftX;
}
