import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../data/services/firestore_service.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(currentTripProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final totalCollected = ref.watch(totalCollectedProvider);
    final remaining = ref.watch(remainingBudgetProvider);
    final pending = ref.watch(pendingCollectionProvider);
    final perHead = ref.watch(perHeadExpenseProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: tripAsync.when(
          data: (t) => Text(t?.name ?? 'Trip'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Trip'),
        ),
        actions: [
          tripAsync.when(
            data: (t) => t != null
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        context.push('/edit-trip/${widget.tripId}');
                      }
                      if (v == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Trip?'),
                            content: const Text(
                              'This will permanently delete the trip and all related data.',
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
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(firestoreServiceProvider)
                              .deleteTrip(widget.tripId);
                          if (context.mounted) context.go('/home');
                        }
                      }
                      if (v == 'share' && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Trip Code: ${t.tripCode}'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Share Code'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return const Center(child: Text('Trip not found'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(currentTripProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.1 : 20,
                vertical: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip header with image
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800&h=300&fit=crop',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                              ),
                            ),
                          ),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      Formatters.dateRange(trip.startDate, trip.endDate),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Code: ${trip.tripCode}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  if (trip.description.isNotEmpty) ...[
                    Text(
                      trip.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Stats grid
                  GridView.count(
                    crossAxisCount: isWide ? 3 : 2,
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
                        value: Formatters.currency(totalExpense),
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
                        valueColor: remaining >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      StatCard(
                        label: 'Collected',
                        value: Formatters.currency(totalCollected),
                        icon: Icons.payments_rounded,
                        iconColor: AppColors.info,
                      ),
                      StatCard(
                        label: 'Pending',
                        value: Formatters.currency(pending > 0 ? pending : 0),
                        icon: Icons.schedule_rounded,
                        iconColor: pending > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      StatCard(
                        label: 'Per Head',
                        value: Formatters.currency(perHead),
                        icon: Icons.person_rounded,
                        iconColor: AppColors.categoryRent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.people_rounded,
                    label: 'Members',
                    subtitle: '${trip.totalMembers} members',
                    color: AppColors.info,
                    onTap: () => context.push('/trip/${widget.tripId}/members'),
                  ),
                  _ActionTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Expenses',
                    subtitle: 'Track all expenses',
                    color: AppColors.warning,
                    onTap: () =>
                        context.push('/trip/${widget.tripId}/expenses'),
                  ),
                  _ActionTile(
                    icon: Icons.analytics_rounded,
                    label: 'Analytics',
                    subtitle: 'Charts & breakdown',
                    color: AppColors.categoryRent,
                    onTap: () =>
                        context.push('/trip/${widget.tripId}/analytics'),
                  ),
                  _ActionTile(
                    icon: Icons.payments_rounded,
                    label: 'Payments Log',
                    subtitle: 'Track contributions & payments',
                    color: AppColors.success,
                    onTap: () =>
                        context.push('/trip/${widget.tripId}/payments'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ShimmerCard(height: 140),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: List.generate(6, (_) => const ShimmerStatCard()),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
