import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class HomeSetupScreen extends ConsumerStatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  ConsumerState<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends ConsumerState<HomeSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _homeIdCtrl = TextEditingController();
  final _homeNameCtrl = TextEditingController();
  bool _loading = false;
  bool _creating = false; // true = buat baru, false = gabung existing
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _homeIdCtrl.dispose();
    _homeNameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);

      if (_creating) {
        final homeId = await repo.createHome(_homeNameCtrl.text.trim());
        await repo.setActiveHome(homeId);
      } else {
        final homeId = _homeIdCtrl.text.trim();
        final exists = await repo.homeExists(homeId);
        if (!exists) {
          setState(() {
            _error = 'ID Rumah tidak ditemukan. Periksa kembali.';
            _loading = false;
          });
          return;
        }
        await repo.joinHome(homeId);
        await repo.setActiveHome(homeId);
      }

      // Navigasi eksplisit ke dashboard setelah berhasil
      if (mounted) context.go('/dashboard');
    } catch (e) {
      print('[HomeSetup] Error: $e');
      setState(() => _error = 'Gagal: $e');
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.bgDark, AppColors.surfaceDark]
                    : [AppColors.primaryMuted, AppColors.bgLight],
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOnDark.withAlpha(isDark ? 40 : 25),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Icon
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
                      'Atur Rumah Anda',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat rumah baru atau masukkan ID\nrumah yang sudah ada',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Toggle: Buat Baru / Gabung
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 10),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ToggleBtn(
                              label: 'Buat Baru',
                              icon: Icons.add_home_rounded,
                              active: _creating,
                              onTap: () => setState(() => _creating = true),
                            ),
                          ),
                          Expanded(
                            child: _ToggleBtn(
                              label: 'Gabung',
                              icon: Icons.login_rounded,
                              active: !_creating,
                              onTap: () => setState(() => _creating = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form
                    Form(
                      key: _formKey,
                      child: _creating
                          ? _CreateHomeForm(ctrl: _homeNameCtrl)
                          : _JoinHomeForm(ctrl: _homeIdCtrl),
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.danger.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Submit button
                    _GradientBtn(
                      label: _creating ? 'Buat Rumah' : 'Gabung Rumah',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle Button ────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Home Form ─────────────────────────────────────────────────────

class _CreateHomeForm extends StatelessWidget {
  final TextEditingController ctrl;
  const _CreateHomeForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Rumah',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Rumah Keluarga',
            prefixIcon:
                const Icon(Icons.home_outlined, color: AppColors.primaryOnDark),
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          validator: (v) =>
              v!.trim().isNotEmpty ? null : 'Nama rumah tidak boleh kosong',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.safe.withAlpha(isDark ? 30 : 15),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.safe.withAlpha(isDark ? 60 : 40)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.safe, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ID Rumah akan dibuat otomatis dan bisa dibagikan ke anggota keluarga.',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Join Home Form ───────────────────────────────────────────────────────

class _JoinHomeForm extends StatelessWidget {
  final TextEditingController ctrl;
  const _JoinHomeForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Rumah',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: 'Masukkan ID Rumah',
            prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primaryOnDark),
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontFamily: 'Poppins',
              letterSpacing: 0,
            ),
          ),
          validator: (v) =>
              v!.trim().isNotEmpty ? null : 'ID Rumah tidak boleh kosong',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.safe.withAlpha(isDark ? 30 : 15),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.safe.withAlpha(isDark ? 60 : 40)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.safe, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Minta ID Rumah dari pemilik atau admin rumah Anda.',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────

class _GradientBtn extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GradientBtn({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOnDark.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
