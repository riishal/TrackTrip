import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:track_tripp/data/services/auth_service.dart';
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

      // Clear any admin auth when member logs in
      await ref.read(authStateProvider.notifier).signOut();

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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.25 : 24,
                vertical: 40,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          size: 40,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Join a Trip',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your name and the trip code shared by the admin',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => Validators.required(v, 'Name'),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trip code
                    TextFormField(
                      controller: _codeController,
                      validator: Validators.tripCode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Trip Code',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        hintText: 'e.g. TRIP2026',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Join button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _joinTrip,
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
                        label: Text(_loading ? 'Joining...' : 'Join Trip'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
