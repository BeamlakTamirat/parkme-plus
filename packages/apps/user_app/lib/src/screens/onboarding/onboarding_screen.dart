import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      useImage: true,
      imagePath: 'assets/images/logo.png',
      icon: Icons.search_outlined,
      title: 'Find Parking Spots',
      description:
          'Discover available parking spaces near you with real-time updates',
      backgroundColor: AppColors.primary,
    ),
    OnboardingData(
      useImage: false,
      imagePath: '',
      icon: Icons.qr_code_scanner_outlined,
      title: 'Easy Check-in',
      description: 'Quick QR code scanning for seamless parking experience',
      backgroundColor: AppColors.primary,
    ),
    OnboardingData(
      useImage: false,
      imagePath: '',
      icon: Icons.payment_outlined,
      title: 'Secure Payments',
      description:
          'Multiple payment options including Telebirr, CBE Birr, and Credit Cards',
      backgroundColor: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    // Mark onboarding as completed
    await ref.read(completeOnboardingProvider(true).future);
    
    if (mounted) {
      context.pushReplacement('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar and skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time and battery indicators area
                  const SizedBox(width: 60),

                  // Skip button
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingPages[index]);
                },
              ),
            ),

            // Bottom section with indicators and buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Navigation buttons
                  Row(
                    children: [
                      // Previous button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (_currentPage > 0) const SizedBox(width: 16),

                      // Next/Get Started button
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingPages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image section
          SizedBox(
            height: 300,
            width: double.infinity,
            child: data.useImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo image
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            data.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Additional decorative elements for first page
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFloatingIcon(Icons.location_on, Colors.red),
                          _buildFloatingIcon(Icons.local_parking, Colors.blue),
                          _buildFloatingIcon(Icons.navigation, Colors.green),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          data.icon,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 60),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class OnboardingData {
  final bool useImage;
  final String imagePath;
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;

  OnboardingData({
    required this.useImage,
    required this.imagePath,
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });
}
