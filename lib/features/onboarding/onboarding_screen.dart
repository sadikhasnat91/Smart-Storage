import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.storage_rounded,
      title: 'Analyze Storage',
      description:
          'Get detailed insights into your device storage. See exactly what\'s taking up space with beautiful visualizations.',
      gradient: LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
      ),
    ),
    _OnboardingPage(
      icon: Icons.find_in_page_rounded,
      title: 'Find Duplicates',
      description:
          'Automatically detect duplicate photos and files. Free up space by removing unnecessary copies.',
      gradient: LinearGradient(
        colors: [Color(0xFF00D9FF), Color(0xFF00C9A7)],
      ),
    ),
    _OnboardingPage(
      icon: Icons.cleaning_services_rounded,
      title: 'Smart Cleaning',
      description:
          'Get intelligent suggestions to clean junk files and optimize your storage safely.',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
      ),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(settingsServiceProvider).isOnboardingComplete = true;
    ref.read(onboardingCompleteProvider.notifier).update(true);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: page.gradient,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                page.icon,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              page.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                            child: Text(
                              page.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Button
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: GlassButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next',
                  icon: _currentPage == _pages.length - 1
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: _onNext,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
