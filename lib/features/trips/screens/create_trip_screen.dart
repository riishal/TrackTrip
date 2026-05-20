import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../providers/app_providers.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  final String? editTripId;
  const CreateTripScreen({super.key, this.editTripId});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _membersCtrl = TextEditingController(text: '1');
  final _codeCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  bool _loading = false;
  bool _isEdit = false;
  TripModel? _existingTrip;

  @override
  void initState() {
    super.initState();
    if (widget.editTripId != null) {
      _isEdit = true;
      _loadTrip();
    } else {
      _codeCtrl.text = _generateCode();
    }
  }

  String _generateCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(r + i * 7) % chars.length]).join();
  }

  Future<void> _loadTrip() async {
    final trip = await ref
        .read(firestoreServiceProvider)
        .getTrip(widget.editTripId!);
    if (trip != null && mounted) {
      setState(() {
        _existingTrip = trip;
        _nameCtrl.text = trip.name;
        _locationCtrl.text = trip.location;
        _descCtrl.text = trip.description;
        _budgetCtrl.text = trip.budgetPerHead.toStringAsFixed(0);
        _membersCtrl.text = trip.totalMembers.toString();
        _codeCtrl.text = trip.tripCode;
        _startDate = trip.startDate;
        _endDate = trip.endDate;
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final user = ref.read(authStateProvider).value;
      final trip = TripModel(
        id: _isEdit ? widget.editTripId! : '',
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        budgetPerHead: double.parse(_budgetCtrl.text),
        totalMembers: int.parse(_membersCtrl.text),
        adminId: user?.uid ?? '',
        tripCode: _codeCtrl.text.trim().toUpperCase(),
        createdAt: _isEdit ? _existingTrip!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      String tripId = '';
      if (_isEdit) {
        await firestore.updateTrip(trip);
        tripId = widget.editTripId!;
      } else {
        tripId = await firestore.createTrip(trip);
      }
      ref.read(selectedTripIdProvider.notifier).state = tripId;
      if (mounted) {
        if (_isEdit) {
          context.pop();
        } else {
          context.go('/home');
        }
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
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _membersCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final budget = double.tryParse(_budgetCtrl.text) ?? 0;
    final members = int.tryParse(_membersCtrl.text) ?? 0;
    final totalBudget = budget * members;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Trip' : 'Create Trip')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? size.width * 0.2 : 20,
          vertical: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => Validators.required(v, 'Trip name'),
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  prefixIcon: Icon(Icons.card_travel_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                validator: (v) => Validators.required(v, 'Location'),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Budget & members
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetCtrl,
                      validator: Validators.positiveAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Budget per Head (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _membersCtrl,
                      validator: (v) => Validators.positiveAmount(v),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Members',
                        prefixIcon: Icon(Icons.people_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total budget display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Budget',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          Formatters.currency(totalBudget),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Trip code
              TextFormField(
                controller: _codeCtrl,
                validator: Validators.tripCode,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Trip Code',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  helperText: 'Members use this code to join',
                  helperStyle: Theme.of(context).textTheme.bodySmall,
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
                      : Text(_isEdit ? 'Update Trip' : 'Create Trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    Formatters.date(date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
