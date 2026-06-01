import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/shared.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      final launched = await SupabaseAuthService.signInWithGoogle();
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: warnAmber,
            content: Text(
              'Could not open Google sign-in. Please try again.',
              style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      // Auth state change is handled by AuthGate's StreamBuilder automatically
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sellRed,
          content: Text(
            'Google sign-in failed: $e',
            style: textStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleDiscordSignIn() async {
    setState(() => isLoading = true);
    try {
      await SupabaseAuthService.signInWithDiscord();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sellRed,
          content: Text(
            'Discord sign-in failed: $e',
            style: textStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: warnAmber,
          content: Text(
            'Enter email and password',
            style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await SupabaseAuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        throw 'Login failed: No user returned';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sellRed,
          content: Text(
            'Login failed: $e',
            style: textStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _createAccount() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: warnAmber,
          content: Text(
            'Enter email and password',
            style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await SupabaseAuthService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        throw 'Sign up failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: buyGreen,
          content: Text(
            'Verification email sent! Please check your inbox.',
            style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sellRed,
          content: Text(
            'Sign up failed: $e',
            style: textStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: VerticalAccentLine(),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Header logo / title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'D',
                            style: monoStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: gold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Text(
                            ' TERMINAL',
                            style: monoStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: textHigh,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldSubtle,
                          border: Border.all(color: borderActive, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INSTITUTIONAL GRADE',
                          style: monoStyle(
                            color: textGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: textStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textHigh,
                          ),
                          children: [
                            const TextSpan(text: 'Terminal '),
                            TextSpan(
                              text: 'Access',
                              style: textStyle(
                                color: gold,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp ? 'CREATE SECURE ACCOUNT' : 'AUTHENTICATE TO PROCEED',
                        style: monoStyle(
                          color: textMid,
                          letterSpacing: 2.0,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "DTrade Capital deploys behavioral AI infrastructure — Trader Genome™, Emotional Volatility Index, Behavioral Shield, and AI Guardian — to detect irrational decisions before they execute. Built for institutional-grade traders who demand edge.",
                          textAlign: TextAlign.center,
                          style: textStyle(
                            color: textMid,
                            fontSize: 11.5,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Social Sign In
                      Row(
                        children: [
                          Expanded(
                            child: _SocialLoginButton(
                              label: 'GOOGLE',
                              icon: Icons.g_mobiledata,
                              onTap: isLoading ? null : _handleGoogleSignIn,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SocialLoginButton(
                              label: 'DISCORD',
                              icon: Icons.discord,
                              onTap: isLoading ? null : _handleDiscordSignIn,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: borderFaint)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR PROTOCOL AUTH',
                              style: monoStyle(
                                color: textLow,
                                letterSpacing: 1.5,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: borderFaint)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Email Address Input
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _InputLabel(label: 'EMAIL ADDRESS'),
                      ),
                      const SizedBox(height: 8),
                      _inputBox(
                        controller: emailController,
                        hint: 'you@example.com',
                        icon: Icons.mail_outline,
                        obscure: false,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Input
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _InputLabel(label: 'PASSWORD'),
                      ),
                      const SizedBox(height: 8),
                      _inputBox(
                        controller: passwordController,
                        hint: '••••••••••',
                        icon: Icons.lock_outline,
                        obscure: obscurePassword,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textMid,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: warnAmber,
                                  content: Text(
                                    'Please enter your email address',
                                    style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                              return;
                            }
                            try {
                              await SupabaseAuthService.resetPassword(email);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: buyGreen,
                                    content: Text(
                                      'Verification email sent!',
                                      style: textStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: sellRed,
                                    content: Text(
                                      'Error: $e',
                                      style: textStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: gold.withOpacity(0.8),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'FORGOT PASSWORD?',
                            style: monoStyle(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                              color: textGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Submit Button
                      _SubmitButton(
                        isLoading: isLoading,
                        label: _isSignUp ? 'SIGN UP' : 'LOGIN',
                        onTap: isLoading
                            ? () {}
                            : (_isSignUp ? _createAccount : _signInWithEmail),
                      ),
                      const SizedBox(height: 18),
                      
                      // Toggle Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? 'Already have an account? ' : 'No active account? ',
                            style: textStyle(color: textMid, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                    });
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: gold,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _isSignUp ? 'Login' : 'Sign up',
                              style: textStyle(
                                fontWeight: FontWeight.bold,
                                color: textGold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Privacy  ·  Terms',
                        style: textStyle(color: textLow, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
      style: monoStyle(color: textHigh, fontSize: 13),
      cursorColor: gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: monoStyle(color: textLow, fontSize: 13),
        prefixIcon: Icon(icon, color: textMid, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: bgCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderFaint, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderActive, width: 1.5),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: monoStyle(
        color: textMid,
        letterSpacing: 1.5,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SocialLoginButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SocialLoginButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _scale = 0.98),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: bgCard,
            border: Border.all(color: borderFaint, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: textHigh,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: textStyle(
                  color: textHigh,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _scale = 0.97),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
      onTapCancel: widget.isLoading ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  widget.label,
                  style: textStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}