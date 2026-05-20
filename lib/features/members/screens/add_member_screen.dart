import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/services/firestore_service.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? editMemberId;
  const AddMemberScreen({super.key, required this.tripId, this.editMemberId});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  String _paymentMethod = 'Cash';
  bool _loading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.editMemberId != null) {
      _isEdit = true;
      _loadMember();
    }
  }

  Future<void> _loadMember() async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.editMemberId)
        .get();
    if (doc.exists && mounted) {
      final m = MemberModel.fromFirestore(doc);
      setState(() {
        _nameCtrl.text = m.name;
        // For edits, we don't display amount or method since they are handled
        // dynamically through the payments history bottom sheet.
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);

      if (_isEdit) {
        final doc = await FirebaseFirestore.instance
            .collection('members')
            .doc(widget.editMemberId)
            .get();
        if (doc.exists) {
          final m = MemberModel.fromFirestore(doc);
          final updatedMember = m.copyWith(
            name: _nameCtrl.text.trim(),
            updatedAt: DateTime.now(),
          );
          await firestore.updateMember(updatedMember);
        }
      } else {
        // Create member initially with 0 paid.
        // If an initial payment is specified, we create a payment transaction,
        // which automatically recalculates and sets the correct paid amount and status!
        final member = MemberModel(
          id: '',
          tripId: widget.tripId,
          name: _nameCtrl.text.trim(),
          phone: '',
          amountPaid: 0,
          paymentMethod: _paymentMethod,
          paymentStatus: 'Pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberId = await firestore.addMember(member);
        final amountPaid = double.tryParse(_amountCtrl.text) ?? 0.0;

        if (amountPaid > 0) {
          final payment = PaymentModel(
            id: '',
            tripId: widget.tripId,
            memberId: memberId,
            memberName: member.name,
            amount: amountPaid,
            paymentMethod: _paymentMethod,
            date: DateTime.now(),
            notes: 'Initial contribution',
            createdAt: DateTime.now(),
          );
          await firestore.addPayment(payment);
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required IconData icon,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppColors.softShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              method,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Member Name' : 'Add Member')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? MediaQuery.of(context).size.width * 0.2 : 20,
          vertical: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => Validators.required(v, 'Name'),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountCtrl,
                  validator: Validators.amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        method: 'Cash',
                        icon: Icons.account_balance_wallet_rounded,
                        selected: _paymentMethod == 'Cash',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        method: 'GPay',
                        icon: Icons.phone_android_rounded,
                        selected: _paymentMethod == 'GPay',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Update Member' : 'Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
