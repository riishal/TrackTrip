import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/empty_state.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String tripId;
  const MembersScreen({super.key, required this.tripId});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final filtered = ref.watch(filteredMembersProvider);
    final search = ref.watch(memberSearchProvider);
    final filter = ref.watch(memberFilterProvider);
    final tripAsync = ref.watch(currentTripProvider);
    final budgetPerHead = tripAsync.value?.budgetPerHead ?? 0.0;

    final totalMembers = membersAsync.value?.length ?? 0;
    final settledCount = membersAsync.value
            ?.where((m) => budgetPerHead > 0 && (budgetPerHead - m.amountPaid) <= 0)
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Members',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (totalMembers > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$settledCount/$totalMembers settled',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: TextField(
              onChanged: (v) => ref.read(memberSearchProvider.notifier).state = v,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () =>
                            ref.read(memberSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'paid', 'pending', 'partial'].map((f) {
                  final selected = filter == f;
                  final chipColor = f == 'paid'
                      ? AppColors.success
                      : f == 'partial'
                          ? AppColors.warning
                          : f == 'pending'
                              ? AppColors.error
                              : AppColors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(memberFilterProvider.notifier).state = f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? chipColor.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? chipColor.withValues(alpha: 0.5)
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? chipColor : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // List
          Expanded(
            child: membersAsync.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    title: 'No members found',
                    subtitle: search.isNotEmpty
                        ? 'Try a different search'
                        : 'Add your first member to get started',
                    actionLabel: search.isEmpty ? 'Add Member' : null,
                    onAction: search.isEmpty
                        ? () => context.push(
                            '/trip/${widget.tripId}/add-member')
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(membersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _MemberCard(
                      member: filtered[i],
                      tripId: widget.tripId,
                      budgetPerHead: budgetPerHead,
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: ShimmerList(itemCount: 5),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'members_fab',
        onPressed: () => context.push('/trip/${widget.tripId}/add-member'),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Add Member',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final MemberModel member;
  final String tripId;
  final double budgetPerHead;

  const _MemberCard({
    required this.member,
    required this.tripId,
    required this.budgetPerHead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidAmount = member.amountPaid;
    final pendingAmount = budgetPerHead - paidAmount;
    final isSettled = pendingAmount <= 0 && budgetPerHead > 0;
    final progress = budgetPerHead > 0
        ? (paidAmount / budgetPerHead).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: Key(member.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: AppColors.error, size: 22),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Delete Member?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'This will delete ${member.name} and all associated payment records.',
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
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(firestoreServiceProvider).deleteMember(member.id, tripId),
      child: GestureDetector(
        onTap: () => context.push('/trip/$tripId/member/${member.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSettled
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSettled
                              ? [
                                  AppColors.success.withValues(alpha: 0.15),
                                  AppColors.success.withValues(alpha: 0.08),
                                ]
                              : [
                                  AppColors.primary.withValues(alpha: 0.12),
                                  AppColors.primary.withValues(alpha: 0.06),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isSettled
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (isSettled)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fully Settled',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppConstants.getPaymentStatusIcon(
                                      member.paymentStatus),
                                  size: 13,
                                  color: member.paymentStatus == 'Partial'
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  member.paymentStatus,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: member.paymentStatus == 'Partial'
                                        ? AppColors.warning
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Amounts column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isSettled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              Formatters.currency(paidAmount),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Paid ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                Formatters.currency(paidAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Due ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                Formatters.currency(
                                    pendingAmount > 0 ? pendingAmount : 0),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Progress bar
                if (budgetPerHead > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceLighter,
                      color: isSettled ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
