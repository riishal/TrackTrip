import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;
      final user = ref.read(authStateProvider).value;
      final memberSession = ref.read(memberSessionProvider);

      if (user != null || isAdminLoggedIn) {
        final uid = user?.uid ?? prefs.getString('admin_uid');
        if (uid != null) {
          try {
            final snap = await FirebaseFirestore.instance
                .collection('trips')
                .where('adminId', isEqualTo: uid)
                .limit(1)
                .get();
            if (!mounted) return;
            if (snap.docs.isNotEmpty) {
              final tripId = snap.docs.first.id;
              ref.read(selectedTripIdProvider.notifier).state = tripId;
              context.go('/home');
            } else {
              context.go('/create-trip');
            }
            return;
          } catch (e) {
            // fallback
          }
        }
        context.go('/home');
      } else if (memberSession != null) {
        context.go('/member-dashboard');
      } else {
        context.go('/login');
      }
    });

    // Fallback timeout to ensure we never stay stuck on splash
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final currentPath = GoRouterState.of(context).uri.path;
      if (currentPath == '/splash') {
        // If still on splash after 5 seconds, force navigation to login
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Track Habit',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your habits and expenses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
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
