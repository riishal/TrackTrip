import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/empty_state.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  final String tripId;
  const ExpensesScreen({super.key, required this.tripId});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final filtered = ref.watch(filteredExpensesProvider);
    final search = ref.watch(expenseSearchProvider);
    final catFilter = ref.watch(expenseCategoryFilterProvider);
    final totalExp = ref.watch(totalExpenseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Expenses',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.sort_rounded,
                  size: 18, color: AppColors.textPrimary),
            ),
            onSelected: (v) =>
                ref.read(expenseSortProvider.notifier).state = v,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date',
                    style: GoogleFonts.inter(fontSize: 13)),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Text('Sort by Amount',
                    style: GoogleFonts.inter(fontSize: 13)),
              ),
              PopupMenuItem(
                value: 'category',
                child: Text('Sort by Category',
                    style: GoogleFonts.inter(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Total Expenses Banner ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.currency(totalExp),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${filtered.length} records',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              onChanged: (v) =>
                  ref.read(expenseSearchProvider.notifier).state = v,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textMuted),
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 20),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () =>
                            ref.read(expenseSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Category Chips ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', ...AppConstants.expenseCategories].map((c) {
                  final selected = catFilter == c;
                  final chipColor = c == 'all'
                      ? AppColors.primary
                      : AppColors.getCategoryColor(c);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(expenseCategoryFilterProvider.notifier)
                          .state = c,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                          c == 'all' ? 'All' : c,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? chipColor
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Expense List ─────────────────────────────────────────────
          Expanded(
            child: expensesAsync.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_outlined,
                    title: 'No expenses found',
                    subtitle: search.isNotEmpty
                        ? 'Try a different search or filter'
                        : 'Start adding expenses to track spending',
                    actionLabel: search.isEmpty ? 'Add Expense' : null,
                    onAction: search.isEmpty
                        ? () => context
                            .push('/trip/${widget.tripId}/add-expense')
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(expensesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _ExpenseCard(
                      expense: filtered[i],
                      tripId: widget.tripId,
                    ),
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(20),
                child: ShimmerList(itemCount: 5, itemHeight: 80),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Something went wrong',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_fab',
        onPressed: () => context.push('/trip/${widget.tripId}/add-expense'),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Expense',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final ExpenseModel expense;
  final String tripId;
  const _ExpenseCard({required this.expense, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = AppColors.getCategoryColor(expense.category);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 22),
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
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete Expense?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
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
                  backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(firestoreServiceProvider).deleteExpense(expense.id),
      child: GestureDetector(
        onTap: () =>
            context.push('/trip/$tripId/edit-expense/${expense.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.softShadow,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppConstants.getCategoryIcon(expense.category),
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title & meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.displayCategory,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${Formatters.dateShort(expense.date)} · ${Formatters.time(expense.date)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                Formatters.currency(expense.amount),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
