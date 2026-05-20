import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../data/services/auth_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final String tripId;
  const AnalyticsScreen({super.key, required this.tripId});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(currentTripProvider).value;
    final totalExp = ref.watch(totalExpenseProvider);
    final totalCol = ref.watch(totalCollectedProvider);
    final remaining = ref.watch(remainingBudgetProvider);
    final perHead = ref.watch(perHeadExpenseProvider);
    final catBreakdown = ref.watch(categoryBreakdownProvider);

    if (trip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final expPercentage = trip.totalBudget > 0
        ? (totalExp / trip.totalBudget * 100).clamp(0.0, 100.0)
        : 0.0;

    final isOverBudget = remaining < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // _AppBarButton(
          //   icon: Icons.edit_rounded,
          //   onTap: () => context.push('/edit-trip/${widget.tripId}'),
          //   tooltip: 'Edit Trip',
          // ),
          // const SizedBox(width: 4),
          _AppBarButton(
            icon: Icons.logout_rounded,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Sign Out?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    'Are you sure you want to sign out from the admin account?',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(selectedTripIdProvider.notifier).state = null;
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header / Banner section (does not scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Trip Identity Card ──────────────────────────────────────
                _TripHeaderCard(
                  tripName: trip.name,
                  tripCode: trip.tripCode,
                  onEdit: () => context.push('/edit-trip/${widget.tripId}'),
                ),
                const SizedBox(height: 16),

                // ── Budget Hero Card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget Usage',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOverBudget
                                  ? 'Over Budget!'
                                  : '${expPercentage.toStringAsFixed(0)}% used',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Formatters.currency(totalExp),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'of ${Formatters.currency(trip.totalBudget)} total',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: expPercentage / 100,
                                  strokeWidth: 7,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                  color: isOverBudget
                                      ? AppColors.error
                                      : expPercentage > 75
                                      ? AppColors.warning
                                      : Colors.white,
                                  strokeCap: StrokeCap.round,
                                ),
                                Text(
                                  '${expPercentage.toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: expPercentage / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          color: isOverBudget
                              ? AppColors.error
                              : expPercentage > 75
                              ? AppColors.warning
                              : Colors.white,
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Body Content below the Fixed Header and Budget Usage Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats Grid ──────────────────────────────────────────────
                  _SectionHeader(title: 'Overview'),
                  const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                StatCard(
                  label: 'Total Spent',
                  value: Formatters.currency(totalExp),
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
                StatCard(
                  label: 'Remaining',
                  value: Formatters.currency(remaining < 0 ? 0 : remaining),
                  icon: Icons.savings_rounded,
                  iconColor: remaining >= 0
                      ? AppColors.success
                      : AppColors.error,
                  valueColor: remaining >= 0 ? null : AppColors.error,
                ),
                StatCard(
                  label: 'Collected',
                  value: Formatters.currency(totalCol),
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.info,
                ),
                StatCard(
                  label: 'Per Head',
                  value: Formatters.currency(perHead),
                  icon: Icons.person_rounded,
                  iconColor: AppColors.categoryRent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Collection Status ───────────────────────────────────────
            _SectionHeader(title: 'Collection Status'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _BarItem(
                    label: 'Collected',
                    value: totalCol,
                    max: trip.totalBudget,
                    color: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _BarItem(
                    label: 'Pending',
                    value: (trip.totalBudget - totalCol).clamp(
                      0,
                      double.infinity,
                    ),
                    max: trip.totalBudget,
                    color: AppColors.error,
                    icon: Icons.pending_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Category Breakdown ──────────────────────────────────────
            if (catBreakdown.isNotEmpty) ...[
              _SectionHeader(title: 'Category Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 44,
                          sections: catBreakdown.entries.map((e) {
                            final color = AppColors.getCategoryColor(e.key);
                            final pct = totalExp > 0
                                ? (e.value / totalExp * 100)
                                : 0.0;
                            return PieChartSectionData(
                              value: e.value,
                              color: color,
                              radius: 48,
                              title: '${pct.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: AppColors.border.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    ...catBreakdown.entries.map((e) {
                      final color = AppColors.getCategoryColor(e.key);
                      final pct = totalExp > 0
                          ? (e.value / totalExp * 100)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.key,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              Formatters.currency(e.value),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ],
),
);
  }
}

// ── Supporting Widgets ──────────────────────────────────────────────────────

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _TripHeaderCard extends StatelessWidget {
  final String tripName;
  final String tripCode;
  final VoidCallback onEdit;

  const _TripHeaderCard({
    required this.tripName,
    required this.tripCode,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Code: $tripCode',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final IconData icon;

  const _BarItem({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              Formatters.currency(value),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${(pct * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceLighter,
            color: color,
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
