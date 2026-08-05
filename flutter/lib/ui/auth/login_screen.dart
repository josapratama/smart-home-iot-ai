import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      if (mounted) _showError('Login gagal. Periksa email dan password Anda.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (result == null && mounted) {
        _showError('Login Google dibatalkan.');
      }
    } catch (e) {
      if (mounted) _showError('Login Google gagal: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.bgDark, AppColors.surfaceDark]
                    : [AppColors.primaryMuted, AppColors.bgLight],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOnDark.withAlpha(isDark ? 40 : 30),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withAlpha(isDark ? 30 : 25),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          // Logo & title
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOnDark.withAlpha(80),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Smart Home',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Selamat datang kembali 👋',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Google Sign-In
                          GoogleSignInButton(
                            onPressed: _loginWithGoogle,
                            isLoading: _googleLoading,
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'atau',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primaryOnDark,
                              ),
                            ),
                            validator: (v) =>
                                v!.contains('@') ? null : 'Email tidak valid',
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: AppColors.primaryOnDark,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                v!.length >= 6 ? null : 'Minimal 6 karakter',
                          ),
                          const SizedBox(height: 28),

                          // Login button
                          GradientButton(
                            label: 'Masuk',
                            onPressed: _login,
                            isLoading: _loading,
                          ),
                          const SizedBox(height: 20),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: AppColors.primaryOnDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
