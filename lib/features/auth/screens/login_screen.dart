import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_tripp/data/services/auth_service.dart';
import 'package:track_tripp/features/auth/screens/widget.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&fit=crop&q=80',
  ];
  int _currentIndex = 0;
  int _nextIndex = 1;
  AnimationController? _fadeCtrl;
  Animation<double>? _fadeAnim;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeInOut);
    _startSlideshow();
  }

  void _startSlideshow() {
    _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _nextIndex = (_currentIndex + 1) % _images.length);
      _fadeCtrl!.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() => _currentIndex = _nextIndex);
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl?.dispose();
    _slideTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(memberSessionProvider.notifier).clearSession();
      await ref
          .read(authStateProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('trips')
            .where('adminId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (!mounted) return;
        if (snap.docs.isNotEmpty) {
          ref.read(selectedTripIdProvider.notifier).state = snap.docs.first.id;
          context.go('/home');
        } else {
          context.go('/create-trip');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;
    final keyboardOpen = mq.viewInsets.bottom > 100;
    final screenHeight = mq.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          CachedNetworkImage(
            key: ValueKey('bg_$_currentIndex'),
            imageUrl: _images[_currentIndex],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF0A1628)),
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF0A1628)),
          ),
          // ── Cross-fade next image ──
          if (_fadeAnim != null)
            FadeTransition(
              opacity: _fadeAnim!,
              child: CachedNetworkImage(
                key: ValueKey('next_$_nextIndex'),
                imageUrl: _images[_nextIndex],
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // ── Gradient scrim ──
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // Hero text
                if (!keyboardOpen)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PillBadge(
                            icon: Icons.flight_takeoff_rounded,
                            label: 'Trip Manager',
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome\nBack',
                            style: GoogleFonts.inter(
                              fontSize: screenHeight < 700 ? 36 : 46,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to manage your trips',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                // ── Bottom sheet ──
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 460 : double.infinity,
                    maxHeight: mq.size.height * 0.72,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: mq.viewInsets.bottom + 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Drag handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Text(
                              'Admin Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Manage payments & members for your trip',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthInputField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Email required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AuthInputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Password required'
                                  : null,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 18,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _PrimaryButton(
                              label: 'Sign In as Admin',
                              loading: _loading,
                              onTap: _submit,
                            ),
                            const SizedBox(height: 18),
                            _OrDivider(),
                            const SizedBox(height: 18),
                            _SecondaryButton(
                              icon: Icons.group_outlined,
                              label: 'Join as Trip Member',
                              onTap: () => context.go('/member-login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ),
        Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
