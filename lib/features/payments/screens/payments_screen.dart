import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../data/services/firestore_service.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  final String tripId;
  const PaymentsScreen({super.key, required this.tripId});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set selected trip ID for providers
    Future.microtask(() {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final totalCollected = ref.watch(totalCollectedProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Record Payment',
            onPressed: () => context.push('/trip/${widget.tripId}/add-payment'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(paymentsProvider),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: Column(
            children: [
              // Header card (Stat summary)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL COLLECTED',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(totalCollected),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track all contributions made by trip members',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search payments by member name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payments list
              Expanded(
                child: paymentsAsync.when(
                  data: (payments) {
                    final filtered = payments.where((p) {
                      return p.memberName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.monetization_on_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'No results found'
                            : 'No Payments Recorded',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try searching with a different member name.'
                            : 'Click the + button to record the first contribution!',
                        actionLabel: _searchQuery.isNotEmpty
                            ? null
                            : 'Record Payment',
                        onAction: _searchQuery.isNotEmpty
                            ? null
                            : () => context.push(
                                '/trip/${widget.tripId}/add-payment',
                              ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final payment = filtered[index];
                        return Dismissible(
                          key: Key(payment.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              color: AppColors.error,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Payment'),
                                content: Text(
                                  'Are you sure you want to delete this payment of ${Formatters.currency(payment.amount)} by ${payment.memberName}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (dir) async {
                            final firestore = ref.read(
                              firestoreServiceProvider,
                            );
                            await firestore.deletePayment(
                              payment.id,
                              payment.memberId,
                              widget.tripId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment deleted successfully'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              payment.memberName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            Formatters.currency(payment.amount),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              payment.notes.isNotEmpty
                                                  ? payment.notes
                                                  : 'No notes',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontStyle: payment.notes.isEmpty
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              payment.paymentMethod,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            Formatters.dateShort(payment.date),
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => context.push(
                                    '/trip/${widget.tripId}/edit-payment/${payment.id}',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, _) => const ShimmerCard(height: 80),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Something went wrong', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
