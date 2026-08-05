import 'package:flutter/material.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class SensorGrid extends StatelessWidget {
  final List<SensorReading> readings;

  const SensorGrid({super.key, required this.readings});

  SensorReading? _latest(String type) {
    final filtered = readings.where((r) => r.type == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.first;
  }

  @override
  Widget build(BuildContext context) {
    final energy = _latest('energy');
    final gas = _latest('gas');
    final fire = _latest('fire');
    final bin = _latest('bin');

    final hasEnergy = energy != null;
    final hasGas = gas != null;
    final hasFire = fire != null;
    final hasBin = bin != null;

    if (!hasEnergy && !hasGas && !hasFire && !hasBin) {
      return const SensorEmptyState();
    }

    final smallCards = <Widget>[
      if (hasGas)
        SensorCard(
          icon: Icons.air_rounded,
          label: 'Gas',
          value: '${gas.gasPpm ?? 0} PPM',
          gradient: (gas.gasPpm ?? 0) > 400 || (gas.gasAlert ?? false)
              ? AppGradients.sensorDanger
              : AppGradients.sensorSafe,
          status: (gas.gasPpm ?? 0) > 400 || (gas.gasAlert ?? false)
              ? 'Bahaya!'
              : 'Aman',
        ),
      if (hasFire)
        SensorCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Api',
          value: (fire.flameDetected ?? false) ? 'TERDETEKSI!' : 'Aman',
          gradient: (fire.flameDetected ?? false)
              ? AppGradients.sensorDanger
              : AppGradients.sensorSafe,
          status: (fire.flameDetected ?? false) ? 'Waspada' : 'Normal',
        ),
      if (hasBin)
        SensorCard(
          icon: Icons.delete_outline_rounded,
          label: 'Sampah',
          value: '${bin.binLevel ?? 0}%',
          gradient: (bin.binLevel ?? 0) > 80
              ? AppGradients.sensorWarning
              : AppGradients.sensorSafe,
          status: (bin.binLevel ?? 0) > 80 ? 'Penuh' : 'Normal',
        ),
    ];

    return Column(
      children: [
        if (hasEnergy) PzemCard(reading: energy),
        if (hasEnergy && smallCards.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (smallCards.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.3,
            children: smallCards,
          ),
      ],
    );
  }
}

// ─── PZEM Card ────────────────────────────────────────────────────────────────

class PzemCard extends StatelessWidget {
  final SensorReading reading;
  const PzemCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final voltage = reading.voltage ?? 0.0;
    final current = reading.current ?? 0.0;
    final power = reading.power ?? 0.0;
    final freq = reading.frequency ?? 0.0;
    final pf = reading.pf ?? 0.0;
    final energyKwh = reading.energy ?? 0.0;

    final isVoltageOk = voltage > 200 && voltage < 240;
    final isFreqOk = freq > 49 && freq < 51;
    final isPowerHigh = power > 2000;

    final String overallStatus;
    final Color statusColor;
    if (!isVoltageOk || !isFreqOk) {
      overallStatus = 'Perlu Cek';
      statusColor = AppColors.warning;
    } else if (isPowerHigh) {
      overallStatus = 'Beban Tinggi';
      statusColor = AppColors.danger;
    } else {
      overallStatus = 'Normal';
      statusColor = AppColors.safe;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.pzem,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated(AppColors.primaryOnDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.overlayDark,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.overlayLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.electric_meter_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monitor Energi', style: AppTextStyles.cardTitle),
                        Text('PZEM-004T', style: AppTextStyles.cardSubtitle),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(50),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: statusColor.withAlpha(120), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(overallStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: AppTextStyles.xs,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                Container(height: 1, color: Colors.white.withAlpha(25)),
                const SizedBox(height: AppSpacing.base),

                // Metrics 2×2
                Row(
                  children: [
                    Expanded(
                      child: _PzemMetric(
                        icon: Icons.electrical_services_rounded,
                        label: 'Tegangan',
                        value: voltage.toStringAsFixed(1),
                        unit: 'V',
                        accentColor:
                            isVoltageOk ? AppColors.safe : AppColors.warning,
                      ),
                    ),
                    _VDivider(),
                    Expanded(
                      child: _PzemMetric(
                        icon: Icons.bolt_rounded,
                        label: 'Arus',
                        value: current.toStringAsFixed(2),
                        unit: 'A',
                        accentColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Container(height: 1, color: Colors.white.withAlpha(15)),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Expanded(
                      child: _PzemMetric(
                        icon: Icons.power_rounded,
                        label: 'Daya',
                        value: power.toStringAsFixed(0),
                        unit: 'W',
                        accentColor:
                            isPowerHigh ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                    _VDivider(),
                    Expanded(
                      child: _PzemMetric(
                        icon: Icons.waves_rounded,
                        label: 'Frekuensi',
                        value: freq.toStringAsFixed(1),
                        unit: 'Hz',
                        accentColor:
                            isFreqOk ? AppColors.safe : AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.base),

                // Footer: kWh & PF
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.energy_savings_leaf_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Energi: ${energyKwh.toStringAsFixed(3)} kWh',
                        style: AppTextStyles.labelSm
                            .copyWith(color: Colors.white70),
                      ),
                      const Spacer(),
                      Container(
                          width: 1,
                          height: 14,
                          color: Colors.white.withAlpha(40)),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.speed_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'PF: ${pf.toStringAsFixed(2)}',
                        style: AppTextStyles.labelSm
                            .copyWith(color: Colors.white70),
                      ),
                    ],
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

class _PzemMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

  const _PzemMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(35),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: AppTextStyles.xs,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: AppTextStyles.xs + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 52, color: Colors.white.withAlpha(20));
}

// ─── Sensor Card ──────────────────────────────────────────────────────────────

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final String status;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = gradient.colors.first;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardColored(baseColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.overlayLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.overlayLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(status, style: AppTextStyles.badge),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.metricValue
                        .copyWith(fontSize: AppTextStyles.lg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.metricLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class SensorGridSkeleton extends StatelessWidget {
  const SensorGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _SkeletonCard(isDark: isDark, height: 220),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: List.generate(2, (_) => _SkeletonCard(isDark: isDark)),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  final double? height;
  const _SkeletonCard({required this.isDark, this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.cardDark : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class SensorEmptyState extends StatelessWidget {
  const SensorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxxl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryOnDark.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors_off_rounded,
                size: 36, color: AppColors.primaryOnDark),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Sensor Belum Aktif',
            style: AppTextStyles.sectionTitle.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pastikan ESP32 sudah terhubung\ndan mengirim data ke sistem',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusChip(
                  icon: Icons.wifi_rounded,
                  label: 'WiFi ESP32',
                  color: AppColors.warning),
              SizedBox(width: 10),
              _StatusChip(
                  icon: Icons.cloud_outlined,
                  label: 'MQTT',
                  color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}
