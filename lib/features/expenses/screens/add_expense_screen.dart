import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/services/firestore_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? editExpenseId;
  const AddExpenseScreen({super.key, required this.tripId, this.editExpenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  String _category = 'Food';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _loading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.editExpenseId != null) {
      _isEdit = true;
      _loadExpense();
    }
  }

  Future<void> _loadExpense() async {
    final doc = await FirebaseFirestore.instance
        .collection('expenses')
        .doc(widget.editExpenseId)
        .get();
    if (doc.exists && mounted) {
      final e = ExpenseModel.fromFirestore(doc);
      setState(() {
        _titleCtrl.text = e.title;
        _amountCtrl.text = e.amount.toStringAsFixed(0);
        _notesCtrl.text = e.notes;
        _category = e.category;
        _customCatCtrl.text = e.customCategory;
        _date = e.date;
        _time = TimeOfDay.fromDateTime(e.date);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final dateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final expense = ExpenseModel(
        id: _isEdit ? widget.editExpenseId! : '',
        tripId: widget.tripId,
        title: _titleCtrl.text.trim(),
        category: _category,
        customCategory: _category == 'Extra' ? _customCatCtrl.text.trim() : '',
        amount: double.parse(_amountCtrl.text),
        date: dateTime,
        notes: _notesCtrl.text.trim(),
        addedBy: 'Admin',
        createdAt: DateTime.now(),
      );
      if (_isEdit) {
        await firestore.updateExpense(expense);
      } else {
        await firestore.addExpense(expense);
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
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _customCatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Expense' : 'Add Expense')),
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
                controller: _titleCtrl,
                validator: (v) => Validators.required(v, 'Title'),
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                validator: Validators.positiveAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // Category
              Text('Category', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.expenseCategories.map((c) {
                  final selected = _category == c;
                  final color = AppColors.getCategoryColor(c);
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppConstants.getCategoryIcon(c),
                          size: 16,
                          color: selected ? color : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(c),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: color.withValues(alpha: 0.15),
                  );
                }).toList(),
              ),
              // Custom category field
              if (_category == 'Extra') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customCatCtrl,
                  validator: (v) => Validators.required(v, 'Custom category'),
                  decoration: const InputDecoration(
                    labelText: 'Custom Category Name',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Date & time row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_date.day}/${_date.month}/${_date.year}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _time.format(context),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_rounded),
                ),
              ),
              const SizedBox(height: 32),
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
                      : Text(_isEdit ? 'Update Expense' : 'Add Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
