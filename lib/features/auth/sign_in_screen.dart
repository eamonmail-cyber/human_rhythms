import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'auth_controller.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e'), backgroundColor: kAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: HRLogo(size: 52, light: true)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Human Rhythms',
                  style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Track your daily routines.\nDiscover what truly works for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, color: Colors.white.withOpacity(0.85), height: 1.5,
                  ),
                ),
                const Spacer(flex: 2),
                // Feature pills
                Wrap(
                  spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                  children: [
                    _pill('📅 Build routines'),
                    _pill('📈 Track progress'),
                    _pill('🌍 Share & inspire'),
                    _pill('🔒 Private by default'),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Get Started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your data stays private. You choose what to share.',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

/// Reusable HR logo mark — two overlapping circles (rhythm / pulse motif)
class HRLogo extends StatelessWidget {
  final double size;
  final bool light;
  const HRLogo({super.key, this.size = 40, this.light = false});

  @override
  Widget build(BuildContext context) {
    final c = light ? Colors.white : kPrimary;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _HRLogoPainter(c)),
    );
  }
}

class _HRLogoPainter extends CustomPainter {
  final Color color;
  _HRLogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = size.width * 0.09..strokeCap = StrokeCap.round;
    final r = size.width * 0.28;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Left circle
    canvas.drawCircle(Offset(cx - r * 0.5, cy), r, paint);
    // Right circle overlapping
    canvas.drawCircle(Offset(cx + r * 0.5, cy), r, paint);
    // Pulse line through centre
    final path = Path();
    path.moveTo(size.width * 0.10, cy);
    path.lineTo(size.width * 0.30, cy);
    path.lineTo(size.width * 0.38, cy - size.height * 0.22);
    path.lineTo(size.width * 0.50, cy + size.height * 0.22);
    path.lineTo(size.width * 0.62, cy - size.height * 0.14);
    path.lineTo(size.width * 0.70, cy);
    path.lineTo(size.width * 0.90, cy);
    canvas.drawPath(path, paint..strokeWidth = size.width * 0.075);
  }

  @override
  bool shouldRepaint(_) => false;
}
