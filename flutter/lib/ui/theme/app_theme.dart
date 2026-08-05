import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — satu-satunya sumber kebenaran untuk warna, tipografi, spacing
// Ubah di sini, berlaku ke seluruh app.
//
// ── GANTI WARNA BRAND ──────────────────────────────────────────────────────
// Cukup ubah tiga konstanta di bawah ini, sisanya menyesuaikan otomatis:
//   brandBase       → warna utama (medium, dipakai di tombol & ikon aktif)
//   brandLight      → versi terang (gradient end, hover)
//   brandDark       → versi gelap  (gradient start, pressed)
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  SATU TEMPAT UNTUK MENGATUR WARNA — ubah hanya 3 baris ini      ║
  // ╚══════════════════════════════════════════════════════════════════╝
  static const _brandBase = Color(0xFF3D5A80); // Slate-blue tenang & gelap
  static const _brandLight = Color(0xFF4E6F99); // Sedikit lebih terang
  static const _brandDark = Color(0xFF2C4A6E); // Lebih gelap untuk gradient

  // ── Brand (alias publik — jangan ubah nama ini) ───────────────────
  static const primary = _brandBase;
  static const primaryLight = _brandLight;
  static const primaryDark = _brandDark;
  static const primaryMuted = Color(0xFFE8EDF4); // Pudar untuk bg light

  /// Versi terang dari primary — warna teks/ikon/aksen di atas background gelap.
  /// Ini satu-satunya yang perlu diubah jika ingin ganti aksen dark mode.
  static const primaryOnDark = Color(0xFF7BAFD4);

  // ── Gradient brand (dipakai di header semua screen) ───────────────────────
  static const gradientStart = _brandDark;
  static const gradientEnd = _brandLight;

  // ── Semantic / Status ─────────────────────────────────────────────────────
  // Warna sesuai fungsi — cukup terang untuk terbaca di cardDark (#181A2E),
  // tapi tidak neon/solid penuh.
  static const safe = Color(0xFF4ADE80); // hijau cerah, terbaca di gelap
  static const warning = Color(0xFFFBBF24); // kuning cerah, terbaca di gelap
  static const danger = Color(0xFFF87171); // merah muda, tidak neon
  static const info = primaryOnDark;

  // Teks DI ATAS warna status sebagai background solid
  static const onSafe = Color(0xFF052E16); // sangat gelap di atas hijau
  static const onWarning = Color(0xFF1C1100); // sangat gelap di atas kuning
  static const onDanger = Color(0xFF2D0707); // sangat gelap di atas merah
  static const onInfo = Color(0xFFFFFFFF);

  // ── Sensor accent (ikon sensor di card gelap) ─────────────────────────────
  static const sensorEnergy = Color(0xFF7BAFD4); // biru brand
  static const sensorGas = Color(0xFFFBBF24); // kuning
  static const sensorFire = Color(0xFFF87171); // merah muda
  static const sensorBin = Color(0xFF4ADE80); // hijau

  // ── Background ─────────────────────────────────────────────────────────────
  static const bgLight = Color(0xFFF5F7FF);
  static const bgDark = Color(0xFF0D0F1A);

  // ── Card / Surface ─────────────────────────────────────────────────────────
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF181A2E);
  static const surfaceDark = Color(0xFF13152A);

  // ── Teks ───────────────────────────────────────────────────────────────────
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);

  // ── Border / Divider ───────────────────────────────────────────────────────
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF1F2137);

  // ── Overlay (untuk dekorasi di atas gradient) ──────────────────────────────
  static const overlayLight = Color(0x28FFFFFF); // white 16%
  static const overlayDark = Color(0x14FFFFFF); // white 8%

  // ── Alias lama (backward compat) ───────────────────────────────────────────
  // Jangan tambah alias baru — pakai nama di atas
  static const secondary = safe;
  static const accent = danger;
  static const energy = sensorEnergy;
  static const gas = sensorGas;
  static const fire = sensorFire;
  static const bin = sensorBin;
  static const online = Color(0xFF4ADE80); // hijau = online/aktif
  static const offline = Color(0xFF9CA3AF); // abu-abu = offline
}

// ─── Gradient Presets ─────────────────────────────────────────────────────────
// Semua gradient di app harus pakai salah satu dari ini

class AppGradients {
  AppGradients._();

  // Header semua screen — konsisten
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );

  // Card sensor PZEM
  static const pzem = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    stops: [0.0, 0.5, 1.0],
  );

  // Card sensor — status aman: dari card gelap → hijau redup
  // Bukan hijau neon — cukup tinted agar terbedakan dari card biasa
  static const sensorSafe = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2318), Color(0xFF14532D)],
  );

  // Card sensor — status bahaya: dari card gelap → merah redup
  static const sensorDanger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F0A0A), Color(0xFF7F1D1D)],
  );

  // Card sensor — status peringatan: dari card gelap → amber redup
  static const sensorWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1205), Color(0xFF78350F)],
  );

  // Alarm card — high: merah sangat gelap
  static const alarmHigh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D0A0A), Color(0xFF7F1D1D)],
  );

  // Alarm card — medium: amber sangat gelap
  static const alarmMedium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F1205), Color(0xFF78350F)],
  );

  // Alarm card — low: hijau sangat gelap
  static const alarmLow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1F12), Color(0xFF14532D)],
  );

  // Energy summary cards
  static const energyTotal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primary],
  );
  static const energyAvg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryLight],
  );
  static const energyMax = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, Color(0xFF6080A8)],
  );
}

// ─── Tipografi ────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = 'Poppins';

  // ── Ukuran font ─────────────────────────────────────────────────────────────
  static const double xs = 10;
  static const double sm = 12;
  static const double base = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 26;
  static const double xxxl = 32;

  // ── Preset style ────────────────────────────────────────────────────────────
  static const screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: xxl,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const screenSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: md + 1,
    fontWeight: FontWeight.w700,
    // Tidak diset warna — ikut theme (putih di dark, gelap di light)
  );

  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: md,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: xs + 1,
    fontWeight: FontWeight.w500,
    color: Colors.white60,
  );

  static const metricValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: xl,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const metricLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: sm,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static const badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: xs,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w400,
  );

  static const bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: sm,
    fontWeight: FontWeight.w400,
  );

  static const labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w600,
  );

  static const labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: sm,
    fontWeight: FontWeight.w600,
  );
}

// ─── Spacing & Radius ─────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double full = 999;
}

// ─── Shadow ───────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 30 : 10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> cardColored(Color color) => [
        BoxShadow(
          color: color.withAlpha(80),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> elevated(Color color) => [
        BoxShadow(
          color: color.withAlpha(100),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.safe,
          surface: AppColors.bgLight,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        fontFamily: AppTextStyles.fontFamily,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: AppTextStyles.lg,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyles.fontFamily,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.primaryMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            textStyle: const TextStyle(
              fontSize: AppTextStyles.md,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            textStyle: const TextStyle(
              fontSize: AppTextStyles.md,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.grey.shade200;
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOnDark,
          brightness: Brightness.dark,
          primary: AppColors.primaryOnDark, // ← terang agar teks/ikon terbaca
          secondary: AppColors.safe,
          surface: AppColors.bgDark,
          onSurface: AppColors.textPrimaryDark,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        fontFamily: AppTextStyles.fontFamily,
        // Paksa semua teks default ke putih di dark mode
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
          bodyMedium: TextStyle(color: AppColors.textPrimaryDark),
          bodySmall: TextStyle(color: AppColors.textSecondaryDark),
          labelLarge: TextStyle(color: AppColors.textPrimaryDark),
          labelMedium: TextStyle(color: AppColors.textSecondaryDark),
          labelSmall: TextStyle(color: AppColors.textSecondaryDark),
          titleLarge: TextStyle(color: AppColors.textPrimaryDark),
          titleMedium: TextStyle(color: AppColors.textPrimaryDark),
          titleSmall: TextStyle(color: AppColors.textPrimaryDark),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: AppTextStyles.lg,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyles.fontFamily,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide:
                const BorderSide(color: AppColors.primaryOnDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOnDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            textStyle: const TextStyle(
              fontSize: AppTextStyles.md,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryOnDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            textStyle: const TextStyle(
              fontSize: AppTextStyles.md,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade600;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected))
              return AppColors.primaryOnDark;
            return AppColors.cardDark;
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
        ),
      );
}
