import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_tripp/features/auth/screens/widget.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/firestore_service.dart';
import '../../../providers/app_providers.dart';

class MemberLoginScreen extends ConsumerStatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  ConsumerState<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends ConsumerState<MemberLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1200&fit=crop&q=80',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1200&fit=crop&q=80',
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
            SnackBar(
              content: Text(
                'Invalid trip code. Please check and try again.',
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
        return;
      }
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
            content: Text(
              'Error: ${e.toString()}',
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
          // ── Cross-fade ──
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
                if (!keyboardOpen)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          Material(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => context.go('/login'),
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _MemberPillBadge(),
                          const SizedBox(height: 20),
                          Text(
                            'Join a\nTrip',
                            style: GoogleFonts.inter(
                              fontSize: screenHeight < 700 ? 36 : 46,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter your name and trip code',
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
                              'Member Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'View expenses & payments for your trip',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthInputField(
                              controller: _nameController,
                              label: 'Your Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              capitalization: TextCapitalization.words,
                              validator: (v) => Validators.required(v, 'Name'),
                            ),
                            const SizedBox(height: 12),
                            AuthInputField(
                              controller: _codeController,
                              label: 'Trip Code',
                              hint: 'e.g. TRIP2026',
                              icon: Icons.vpn_key_outlined,
                              capitalization: TextCapitalization.characters,
                              validator: Validators.tripCode,
                              letterSpacing: 2.5,
                            ),
                            const SizedBox(height: 24),
                            _MemberPrimaryButton(
                              label: 'Join Trip',
                              loading: _loading,
                              onTap: _joinTrip,
                            ),
                            const SizedBox(height: 18),
                            const _MemberOrDivider(),
                            const SizedBox(height: 18),
                            _MemberSecondaryButton(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Sign In as Admin',
                              onTap: () => context.go('/login'),
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

// ── Local widgets (private to this file) ─────────────────────────────────────

class _MemberPillBadge extends StatelessWidget {
  const _MemberPillBadge();

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
          const Icon(Icons.group_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Trip Member',
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

class _MemberPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _MemberPrimaryButton({
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

class _MemberOrDivider extends StatelessWidget {
  const _MemberOrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
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
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }
}

class _MemberSecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MemberSecondaryButton({
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
