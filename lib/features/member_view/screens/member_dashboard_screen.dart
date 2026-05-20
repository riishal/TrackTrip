import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/expense_model.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(memberSessionProvider);
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go('/member-login'),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tripAsync = ref.watch(currentTripProvider);
    final totalExp = ref.watch(totalExpenseProvider);
    final remaining = ref.watch(remainingBudgetProvider);
    final perHead = ref.watch(perHeadExpenseProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final membersAsync = ref.watch(membersProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: tripAsync.when(
            data: (trip) {
              if (trip == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Trip not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(memberSessionProvider.notifier)
                              .clearSession();
                          if (context.mounted) context.go('/member-login');
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }

              final horizontalPadding = isWide
                  ? MediaQuery.of(context).size.width * 0.1
                  : 20.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed Header at top (does not scroll)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              session.memberName[0].toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, ${session.memberName}',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                trip.name,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'Leave Trip?',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to log out and leave this trip session?',
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
                                    child: const Text('Leave'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref
                                  .read(memberSessionProvider.notifier)
                                  .clearSession();
                              ref.read(selectedTripIdProvider.notifier).state =
                                  null;
                              if (context.mounted) {
                                context.go('/member-login');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fixed Trip image banner (does not scroll)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  'https://kanyakumaritouristplaces.com/wp-content/uploads/2025/06/Kodaikanal.webp',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.black.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        trip.location,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        Formatters.dateRange(
                                          trip.startDate,
                                          trip.endDate,
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Scrollable Body Content below the Fixed Header and Banner
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(currentTripProvider);
                        ref.invalidate(expensesProvider);
                        ref.invalidate(membersProvider);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          4,
                          horizontalPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats
                      GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: 'Total Budget',
                            value: Formatters.currency(trip.totalBudget),
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColors.primary,
                          ),
                          StatCard(
                            label: 'Total Spent',
                            value: Formatters.currency(totalExp),
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.warning,
                          ),
                          StatCard(
                            label: 'Remaining',
                            value: Formatters.currency(remaining),
                            icon: Icons.savings_rounded,
                            iconColor: remaining >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          StatCard(
                            label: 'Per Head',
                            value: Formatters.currency(perHead),
                            icon: Icons.person_rounded,
                            iconColor: AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Members payment status
                      Text(
                        'Payment Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      membersAsync.when(
                        data: (members) => Column(
                          children: members.map((m) {
                            final statusColor = m.paymentStatus == 'Paid'
                                ? AppColors.success
                                : (m.paymentStatus == 'Partial'
                                      ? AppColors.warning
                                      : AppColors.error);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppColors.softShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        m.name[0].toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      m.paymentStatus,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Formatters.currency(m.amountPaid),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        loading: () =>
                            ShimmerList(itemCount: 3, itemHeight: 60),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 24),
                      // Recent expenses
                      Text(
                        'Recent Expenses',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      expensesAsync.when(
                        data: (expenses) {
                          if (expenses.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppColors.softShadow,
                              ),
                              child: Center(
                                child: Text(
                                  'No expenses yet',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            );
                          }
                          final recent = expenses.take(10).toList();
                          return Column(
                            children: recent
                                .map((e) => _ExpenseItem(expense: e))
                                .toList(),
                          );
                        },
                        loading: () =>
                            ShimmerList(itemCount: 3, itemHeight: 70),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.getCategoryColor(expense.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              AppConstants.getCategoryIcon(expense.category),
              color: catColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${expense.displayCategory} • ${Formatters.dateShort(expense.date)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(expense.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
