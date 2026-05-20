import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/firestore_service.dart';
import '../../../providers/app_providers.dart';

class MemberLoginScreen extends ConsumerStatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  ConsumerState<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends ConsumerState<MemberLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final trip = await firestore.getTripByCode(
        _codeController.text.trim().toUpperCase(),
      );

      if (trip == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid trip code. Please check and try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Set member session
      await ref
          .read(memberSessionProvider.notifier)
          .saveSession(
            MemberSession(
              memberName: _nameController.text.trim(),
              tripId: trip.id,
              tripCode: _codeController.text.trim().toUpperCase(),
            ),
          );
      ref.read(selectedTripIdProvider.notifier).state = trip.id;

      if (mounted) context.go('/member-dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back Button & Header Icon Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => context.go('/login'),
                              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                padding: const EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_rounded,
                                size: 24,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer to balance back button
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Join a Trip',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your name and the trip code shared by the admin to start tracking.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          validator: (v) => Validators.required(v, 'Name'),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            hintText: 'Enter your full name',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Trip Code Input
                        TextFormField(
                          controller: _codeController,
                          validator: Validators.tripCode,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Trip Code',
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                            hintText: 'e.g. TRIP2026',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Join Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _joinTrip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded, size: 20),
                            label: Text(
                              _loading ? 'Joining Trip...' : 'Join Trip',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
