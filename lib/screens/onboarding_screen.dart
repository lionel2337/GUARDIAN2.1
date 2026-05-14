/// Onboarding screen — permission requests, feature intro, sign-in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _permissionsGranted = false;

  // Sign-in form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSignUp = false;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Welcome to Guardians AI',
      description:
          'Your personal safety companion. We use on-device AI to keep you '
          'and your loved ones safe — even without internet.',
      gradient: AppColors.primaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.location_on_rounded,
      title: 'Real-Time Protection',
      description:
          'Track family members in real time, monitor journeys with '
          'deviation detection, and view risk zones on the map.',
      gradient: LinearGradient(
        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
      ),
    ),
    _OnboardingPage(
      icon: Icons.sensors_rounded,
      title: 'AI-Powered Detection',
      description:
          'Our AI detects falls, fights, and screams automatically. '
          'All processing happens on your device — no internet needed.',
      gradient: LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFFFB74D)],
      ),
    ),
    _OnboardingPage(
      icon: Icons.people_rounded,
      title: 'Community Safety',
      description:
          'Report incidents to warn others in real time. Together, '
          'we build safer communities across Cameroon.',
      gradient: LinearGradient(
        colors: [Color(0xFFE53935), Color(0xFFEF5350)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Navigate to home when authenticated.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length + 2, // +1 permissions, +1 sign-in
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    if (index < _pages.length) {
                      return _buildFeaturePage(_pages[index]);
                    }
                    if (index == _pages.length) {
                      return _buildPermissionsPage();
                    }
                    return _buildSignInPage(auth);
                  },
                ),
              ),

              // Page indicator + next button
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots
                    Row(
                      children: List.generate(
                        _pages.length + 2,
                        (i) => AnimatedContainer(
                          duration: AppAnimations.fast,
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentPage
                                ? AppColors.accent
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started
                    if (_currentPage < _pages.length + 1)
                      FloatingActionButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: AppAnimations.normal,
                            curve: Curves.easeInOut,
                          );
                        },
                        backgroundColor: AppColors.accent,
                        child: const Icon(Icons.arrow_forward_rounded),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: page.gradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(page.icon, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: AppColors.accent),
          const SizedBox(height: 24),
          const Text(
            'Permissions Required',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guardians AI needs the following permissions to protect you:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _permissionTile(Icons.location_on, 'Location',
              'Real-time tracking and risk detection'),
          _permissionTile(
              Icons.mic, 'Microphone', 'Scream and keyword detection'),
          _permissionTile(Icons.directions_run, 'Activity Recognition',
              'Fall and fight detection'),
          _permissionTile(Icons.notifications, 'Notifications',
              'Emergency alerts and reminders'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: Icon(
                _permissionsGranted ? Icons.check_circle : Icons.lock_open,
              ),
              label: Text(
                _permissionsGranted ? 'Permissions Granted ✓' : 'Grant Permissions',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _permissionsGranted ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile(IconData icon, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPage(AuthState auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to sync your data across devices',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Anonymous sign-in
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () => ref.read(authProvider.notifier).signInAnonymously(),
              icon: const Icon(Icons.person_outline),
              label: const Text('Continue Without Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ]),
          const SizedBox(height: 24),

          // Email sign-in form
          if (_isSignUp) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textHint),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textHint),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),

          // Error message
          if (auth.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(auth.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _submitAuth,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : "Don't have an account? Sign Up",
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.activityRecognition,
      Permission.notification,
    ].request();

    setState(() {
      _permissionsGranted = statuses.values.every(
        (s) => s.isGranted || s.isLimited,
      );
    });
  }

  void _submitAuth() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    if (_isSignUp) {
      ref.read(authProvider.notifier).signUp(
            email,
            password,
            _nameController.text.trim(),
            _phoneController.text.trim(),
          );
    } else {
      ref.read(authProvider.notifier).signInWithEmail(email, password);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
