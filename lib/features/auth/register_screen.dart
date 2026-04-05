import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'auth_controller.dart';
import 'sign_in_screen.dart' show HRLogo;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();

  bool _loading  = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  late AnimationController _anim;
  late Animation<double>   _fade;

  // Password must be 8+ chars with at least one letter and one number.
  static final _passRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await registerWithEmail(
        _nameCtrl.text,
        _emailCtrl.text,
        _passCtrl.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: HRLogo(size: 44, light: true)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start tracking your human rhythms',
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 32),

                // Error banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full name
                      TextFormField(
                        controller: _nameCtrl,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Full name'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Full name is required.';
                          if (v.trim().length < 2) return 'Name must be at least 2 characters.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required.';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure1,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Password', suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        )),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required.';
                          if (!_passRegex.hasMatch(v)) {
                            return 'Min 8 characters with at least one letter and one number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm password
                      TextFormField(
                        controller: _pass2Ctrl,
                        obscureText: _obscure2,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Confirm password', suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        )),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password.';
                          if (v != _passCtrl.text) return 'Passwords do not match.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Sign In',
                          style: TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) => InputDecoration(
  labelText: label,
  counterText: '',
  suffixIcon: suffixIcon,
  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.white, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red.shade300),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
  ),
  errorStyle: TextStyle(color: Colors.red.shade200),
);
