import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

// ─── Model agregasi per jam ───────────────────────────────────────────────

class _HourlyPoint {
  final DateTime hour;
  final double avgCurrent;
  final double avgPower;

  const _HourlyPoint({
    required this.hour,
    required this.avgCurrent,
    required this.avgPower,
  });
}

/// Agregasi readings menjadi rata-rata per jam
List<_HourlyPoint> _aggregateByHour(List<SensorReading> readings) {
  if (readings.isEmpty) return [];

  // Sort ascending by timestamp
  final sorted = [...readings]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Group by hour bucket
  final Map<String, List<SensorReading>> buckets = {};
  for (final r in sorted) {
    final key =
        '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}'
        '-${r.timestamp.day.toString().padLeft(2, '0')}'
        ' ${r.timestamp.hour.toString().padLeft(2, '0')}';
    buckets.putIfAbsent(key, () => []).add(r);
  }

  // Hitung rata-rata per bucket
  final points = buckets.entries.map((e) {
    final list = e.value;
    final avgCurrent =
        list.map((r) => r.current ?? 0.0).reduce((a, b) => a + b) / list.length;
    final avgPower =
        list.map((r) => r.power ?? 0.0).reduce((a, b) => a + b) / list.length;
    return _HourlyPoint(
      hour: list.first.timestamp,
      avgCurrent: avgCurrent,
      avgPower: avgPower,
    );
  }).toList();

  // Sort hasil agregasi
  points.sort((a, b) => a.hour.compareTo(b.hour));
  return points;
}

// ─── Widget utama ─────────────────────────────────────────────────────────

class EnergyChartCard extends StatefulWidget {
  final List<SensorReading> readings;

  const EnergyChartCard({super.key, required this.readings});

  @override
  State<EnergyChartCard> createState() => _EnergyChartCardState();
}

class _EnergyChartCardState extends State<EnergyChartCard> {
  int _selectedMetric = 0; // 0 = Arus (A), 1 = Daya (W)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = _aggregateByHour(widget.readings);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card(isDark),
      ),
      child: points.isEmpty
          ? _EmptyChart(isDark: isDark)
          : _ChartContent(
              points: points,
              isDark: isDark,
              selectedMetric: _selectedMetric,
              onMetricChanged: (v) => setState(() => _selectedMetric = v),
            ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final bool isDark;
  const _EmptyChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada data energi',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data akan muncul setelah sensor aktif',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chart content ────────────────────────────────────────────────────────

class _ChartContent extends StatelessWidget {
  final List<_HourlyPoint> points;
  final bool isDark;
  final int selectedMetric;
  final ValueChanged<int> onMetricChanged;

  const _ChartContent({
    required this.points,
    required this.isDark,
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArus = selectedMetric == 0;
    final color = isArus ? AppColors.primaryOnDark : AppColors.safe;
    final unit = isArus ? 'A' : 'W';

    final values = isArus
        ? points.map((p) => p.avgCurrent).toList()
        : points.map((p) => p.avgPower).toList();

    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: info + toggle metrik
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${points.length} titik (rata-rata/jam)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            _MetricToggle(
              selected: selectedMetric,
              onChanged: onMetricChanged,
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Grafik
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxVal == 0 ? 1 : maxVal,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxVal / 4,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toStringAsFixed(isArus ? 1 : 0)}$unit',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    // Tampilkan label setiap ~6 jam agar tidak padat
                    interval: (points.length / 5).ceilToDouble().clamp(1, 24),
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox();
                      }
                      final dt = points[idx].hour;
                      // Jika rentang > 1 hari, tampilkan tanggal; jika tidak, jam
                      final spanDays =
                          points.last.hour.difference(points.first.hour).inDays;
                      final label = spanDays >= 1
                          ? DateFormat('dd/MM').format(dt)
                          : DateFormat('HH:mm').format(dt);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: isDark ? AppColors.cardDark : Colors.white,
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final dt = idx >= 0 && idx < points.length
                        ? points[idx].hour
                        : null;
                    final timeStr =
                        dt != null ? DateFormat('dd/MM HH:mm').format(dt) : '';
                    return LineTooltipItem(
                      '$timeStr\n${s.y.toStringAsFixed(isArus ? 2 : 0)} $unit',
                      TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: values.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: color,
                  barWidth: 2.5,
                  // Sembunyikan dot — terlalu banyak titik
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withAlpha(60),
                        color.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isArus ? 'Rata-rata Arus (A)' : 'Rata-rata Daya (W)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Toggle Metrik ────────────────────────────────────────────────────────

class _MetricToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _MetricToggle({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'Arus',
            active: selected == 0,
            color: AppColors.primaryOnDark,
            isDark: isDark,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 2),
          _ToggleBtn(
            label: 'Daya',
            active: selected == 1,
            color: AppColors.safe,
            isDark: isDark,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.white
                : (isDark ? Colors.white38 : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}
