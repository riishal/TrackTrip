import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/payment_model.dart';

import '../../../data/services/firestore_service.dart';
import '../../../providers/app_providers.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? editPaymentId;

  const AddPaymentScreen({super.key, required this.tripId, this.editPaymentId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedMemberId;
  String? _selectedMemberName;
  String _selectedMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  bool _loading = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
      if (widget.editPaymentId != null) {
        _loadPayment();
      } else {
        setState(() => _initializing = false);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPayment() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.editPaymentId)
          .get();

      if (doc.exists && mounted) {
        final payment = PaymentModel.fromFirestore(doc);
        setState(() {
          _selectedMemberId = payment.memberId;
          _selectedMemberName = payment.memberName;
          _amountController.text = payment.amount.toString();
          _selectedMethod = payment.paymentMethod;
          _selectedDate = payment.date;
          _notesController.text = payment.notes;
          _initializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a member'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);

      final payment = PaymentModel(
        id: widget.editPaymentId ?? '',
        tripId: widget.tripId,
        memberId: _selectedMemberId!,
        memberName: _selectedMemberName!,
        amount: double.parse(_amountController.text.trim()),
        paymentMethod: _selectedMethod,
        date: _selectedDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.editPaymentId != null) {
        await firestore.updatePayment(payment);
      } else {
        await firestore.addPayment(payment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editPaymentId != null
                  ? 'Payment updated successfully'
                  : 'Payment recorded successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
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
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editPaymentId != null ? 'Edit Payment' : 'Record Payment',
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_card_rounded,
                        size: 36,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Select Member Dropdown
                  membersAsync.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Text(
                            'Please add members to this trip first before recording payments.',
                            style: TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedMemberId,
                        validator: (v) => v == null ? 'Select member' : null,
                        decoration: const InputDecoration(
                          labelText: 'Trip Member',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        dropdownColor: AppColors.surface,
                        items: members.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(m.name),
                          );
                        }).toList(),
                        onChanged: widget.editPaymentId != null
                            ? null // Cannot change member when editing
                            : (id) {
                                if (id != null) {
                                  final m = members.firstWhere(
                                    (x) => x.id == id,
                                  );
                                  setState(() {
                                    _selectedMemberId = id;
                                    _selectedMemberName = m.name;
                                  });
                                }
                              },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => Text(
                      'Error loading members: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    validator: Validators.amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (₹)',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment_rounded),
                    ),
                    dropdownColor: AppColors.surface,
                    items: AppConstants.paymentMethods.map((m) {
                      return DropdownMenuItem<String>(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (method) {
                      if (method != null) {
                        setState(() => _selectedMethod = method);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date selector
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        Formatters.date(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.editPaymentId != null
                                      ? 'Update'
                                      : 'Record',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
