import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/services/firestore_service.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String memberId;

  const MemberDetailsScreen({
    super.key,
    required this.tripId,
    required this.memberId,
  });

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _submitting = false;
  bool _initializedPending = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _recordPayment(MemberModel member, double budgetPerHead) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount greater than 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);

    try {
      final payment = PaymentModel(
        id: '',
        tripId: widget.tripId,
        memberId: member.id,
        memberName: member.name,
        amount: amount,
        paymentMethod: _paymentMethod,
        date: DateTime.now(),
        notes: _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addPayment(payment);

      _notesCtrl.clear();
      final newPending = budgetPerHead - (member.amountPaid + amount);
      if (newPending > 0) {
        _amountCtrl.text = newPending.toStringAsFixed(0);
      } else {
        _amountCtrl.clear();
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Recorded ₹${amount.toStringAsFixed(0)} payment for ${member.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(currentTripProvider);
    final budgetPerHead = tripAsync.value?.budgetPerHead ?? 0.0;

    final membersAsync = ref.watch(membersProvider);
    final member = membersAsync.value?.firstWhere(
      (m) => m.id == widget.memberId,
      orElse: () => MemberModel(
        id: widget.memberId,
        tripId: widget.tripId,
        name: 'Loading...',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final paidAmount = member?.amountPaid ?? 0.0;
    final pendingAmount = budgetPerHead - paidAmount;
    final isSettled = pendingAmount <= 0 && budgetPerHead > 0;
    final progress =
        budgetPerHead > 0 ? (paidAmount / budgetPerHead).clamp(0.0, 1.0) : 0.0;

    if (member != null &&
        !_initializedPending &&
        membersAsync.value != null &&
        budgetPerHead > 0) {
      _initializedPending = true;
      final pending = budgetPerHead - member.amountPaid;
      if (pending > 0) {
        _amountCtrl.text = pending.toStringAsFixed(0);
      }
    }

    final paymentsAsync = ref.watch(paymentsProvider);
    final memberPayments = paymentsAsync.value
            ?.where((p) => p.memberId == widget.memberId)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          member?.name ?? 'Member Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (member != null && member.name != 'Loading...')
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => context.push(
                    '/trip/${widget.tripId}/edit-member/${member.id}'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppColors.primary, size: 16),
                ),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        data: (_) {
          if (member == null || member.name == 'Loading...') {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Member Hero Banner ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSettled
                        ? LinearGradient(
                            colors: [
                              AppColors.success.withValues(alpha: 0.9),
                              AppColors.success.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isSettled ? AppColors.success : AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar circle
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSettled ? '✓ Fully Settled' : member.paymentStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      if (budgetPerHead > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${paidAmount.toStringAsFixed(0)} paid',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '₹${budgetPerHead.toStringAsFixed(0)} target',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            color: Colors.white,
                            minHeight: 7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats Row ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Target',
                        value: Formatters.currency(budgetPerHead),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatPill(
                        label: 'Paid',
                        value: Formatters.currency(paidAmount),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatPill(
                        label: isSettled ? 'Status' : 'Pending',
                        value: isSettled
                            ? 'Done'
                            : Formatters.currency(
                                pendingAmount > 0 ? pendingAmount : 0),
                        color: isSettled ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Record Payment Form ────────────────────────────────
                if (!isSettled) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.6)),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_card_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Record Payment',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Amount (₹)',
                                prefixIcon:
                                    const Icon(Icons.currency_rupee_rounded),
                                labelStyle: GoogleFonts.inter(fontSize: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final val = double.tryParse(v);
                                if (val == null || val <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesCtrl,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Note (optional)',
                                prefixIcon: const Icon(Icons.note_alt_outlined),
                                labelStyle: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Payment Method',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _MethodChip(
                                    method: 'Cash',
                                    icon:
                                        Icons.account_balance_wallet_rounded,
                                    selected: _paymentMethod == 'Cash',
                                    onTap: () => setState(
                                        () => _paymentMethod = 'Cash'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MethodChip(
                                    method: 'GPay',
                                    icon: Icons.phone_android_rounded,
                                    selected: _paymentMethod == 'GPay',
                                    onTap: () => setState(
                                        () => _paymentMethod = 'GPay'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () =>
                                        _recordPayment(member, budgetPerHead),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_rounded,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Record Payment',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Payment History ────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Payment History',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${memberPayments.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: paymentsAsync.when(
                    data: (_) {
                      if (memberPayments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(36),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: AppColors.textMuted.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No payments recorded yet',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: memberPayments.length,
                        separatorBuilder: (_, index) => Divider(
                          height: 1,
                          color: AppColors.border.withValues(alpha: 0.4),
                          indent: 66,
                        ),
                        itemBuilder: (context, idx) {
                          final payment = memberPayments[idx];
                          final isGPay = payment.paymentMethod == 'GPay';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isGPay
                                        ? AppColors.primary
                                        : AppColors.success)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGPay
                                    ? Icons.phone_android_rounded
                                    : Icons.account_balance_wallet_rounded,
                                color: isGPay
                                    ? AppColors.primary
                                    : AppColors.success,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              payment.paymentMethod,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (payment.notes.isNotEmpty)
                                  Text(
                                    payment.notes,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  Formatters.date(payment.date),
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${Formatters.currency(payment.amount)}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          'Delete Payment?',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        content: Text(
                                          'Remove ₹${payment.amount.toStringAsFixed(0)} payment record?',
                                          style: GoogleFonts.inter(
                                              fontSize: 14),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await ref
                                          .read(firestoreServiceProvider)
                                          .deletePayment(
                                            payment.id,
                                            member.id,
                                            widget.tripId,
                                          );
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Payment deleted'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: Text('Failed to load payment history.')),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
            child: Text('An error occurred while loading member data.')),
      ),
    );
  }
}

// ── Supporting Widgets ───────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String method;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.method,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              method,
              style: GoogleFonts.inter(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
