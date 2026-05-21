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

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  ConsumerState<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  bool _showAllMembers = false;

  @override
  Widget build(BuildContext context) {
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
                              style: Theme.of(context).textTheme.titleLarge
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
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
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
                                  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&fit=crop&q=80',
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
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
                            const SizedBox(height: 24),
                            // Members payment status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Status',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                membersAsync.whenOrNull(
                                      data: (members) => members.length > 4
                                          ? TextButton(
                                              onPressed: () => setState(
                                                () => _showAllMembers =
                                                    !_showAllMembers,
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: Size.zero,
                                              ),
                                              child: Text(
                                                _showAllMembers
                                                    ? 'Show Less'
                                                    : 'See All',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ) ??
                                    const SizedBox.shrink(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            membersAsync.when(
                              data: (members) {
                                if (members.isEmpty) {
                                  return const Text('No members yet');
                                }
                                final budgetPerHead =
                                    trip.totalBudget / members.length;
                                final sortedMembers = List.from(members)
                                  ..sort(
                                    (a, b) =>
                                        b.updatedAt.compareTo(a.updatedAt),
                                  );
                                final displayMembers = _showAllMembers
                                    ? sortedMembers
                                    : sortedMembers.take(4).toList();

                                return Column(
                                  children: displayMembers.map((m) {
                                    return _PaymentCard(
                                      member: m,
                                      budgetPerHead: budgetPerHead,
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () =>
                                  ShimmerList(itemCount: 3, itemHeight: 60),
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

class _PaymentCard extends StatelessWidget {
  final dynamic member;
  final double budgetPerHead;

  const _PaymentCard({required this.member, required this.budgetPerHead});

  @override
  Widget build(BuildContext context) {
    final statusColor = member.paymentStatus == 'Paid'
        ? AppColors.success
        : (member.paymentStatus == 'Partial'
              ? AppColors.warning
              : AppColors.error);

    final pending = (budgetPerHead - member.amountPaid).clamp(
      0.0,
      double.infinity,
    );
    final pct = budgetPerHead > 0
        ? (member.amountPaid / budgetPerHead).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${Formatters.dateShort(member.updatedAt)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  member.paymentStatus,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PaymentAmountInfo(
                  label: 'Paid Amount',
                  amount: member.amountPaid,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _PaymentAmountInfo(
                    label: 'Pending Amount',
                    amount: pending,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentAmountInfo extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _PaymentAmountInfo({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.currency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
