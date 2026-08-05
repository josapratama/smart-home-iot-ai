import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/widgets/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
            _emailCtrl.text.trim(),
            _passCtrl.text.trim(),
            _nameCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [AppColors.bgDark, AppColors.surfaceDark]
                    : [AppColors.bgLight, AppColors.primaryMuted],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withAlpha(isDark ? 40 : 30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
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
                              const SizedBox(height: 16),
                              Text(
                                'Buat Akun',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Daftar untuk mulai mengontrol rumah Anda',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Name field
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.primaryOnDark,
                                  ),
                                ),
                                validator: (v) => v!.isNotEmpty
                                    ? null
                                    : 'Nama tidak boleh kosong',
                              ),
                              const SizedBox(height: 16),

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
                                validator: (v) => v!.contains('@')
                                    ? null
                                    : 'Email tidak valid',
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
                                validator: (v) => v!.length >= 6
                                    ? null
                                    : 'Minimal 6 karakter',
                              ),
                              const SizedBox(height: 32),

                              GradientButton(
                                label: 'Daftar Sekarang',
                                onPressed: _register,
                                isLoading: _loading,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun? ',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        color: AppColors.primaryOnDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
