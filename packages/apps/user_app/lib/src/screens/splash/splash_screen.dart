import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:shared/src/config/appwrite_config.dart';
import '../../providers/simple_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _phoneController;
  late AnimationController _carsController;

  late Animation<double> _phoneAnimation;
  late Animation<double> _carsAnimation;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _phoneController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _carsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Phone scaling and positioning
    _phoneAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _phoneController,
      curve: Curves.elasticOut,
    ));

    // Cars sliding from sides
    _carsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _carsController,
      curve: Curves.easeOutBack,
    ));

    // Title animations
    _titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));

    // Subtitle animations
    _subtitleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    ));

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimationSequence() async {
    // Initialize backend
    await AppwriteConfig.initialize();

    // Start phone animation
    await _phoneController.forward();

    // Wait a bit, then start cars
    await Future.delayed(const Duration(milliseconds: 300));
    _carsController.forward();

    // Wait a bit, then start title
    await Future.delayed(const Duration(milliseconds: 500));
    _titleController.forward();

    // Wait a bit, then start subtitle
    await Future.delayed(const Duration(milliseconds: 300));
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    _checkAppState();
  }

  void _checkAppState() async {
    if (!mounted) return;

    // Check if user is authenticated
    final isAuthenticated = await ref.read(isAuthenticatedProvider.future);
    
    if (isAuthenticated) {
      // User is logged in, go directly to home
      _navigateToHome();
    } else {
      // User is not logged in, check if first time
      final isFirstTime = await ref.read(isFirstTimeUserProvider.future);
      
      if (isFirstTime) {
        // First time user, show onboarding
        _navigateToOnboarding();
      } else {
        // Returning user, go to sign in
        _navigateToSignIn();
      }
    }
  }

  void _navigateToOnboarding() {
    if (mounted) {
      context.pushReplacement('/onboarding');
    }
  }

  void _navigateToSignIn() {
    if (mounted) {
      context.pushReplacement('/sign-in');
    }
  }

  void _navigateToHome() {
    if (mounted) {
      context.pushReplacement('/home');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _phoneController.dispose();
    _carsController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5A623), // Orange top
              Color(0xFFFF8C00), // Darker orange bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with WePark title
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _titleController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: const Text(
                            'WE PARK',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4A4A4A),
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 6,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Middle section with 3D phone and cars
              Expanded(
                flex: 4,
                child: Center(
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_phoneController, _carsController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _phoneAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Phone base
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateX(0.1),
                              child: Container(
                                width: 280,
                                height: 500,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Parking lot surface
                                        Positioned.fill(
                                          child: Container(
                                            margin: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2D2D2D),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: CustomPaint(
                                              painter: ParkingLotPainter(),
                                            ),
                                          ),
                                        ),

                                        // Cars
                                        _buildAnimatedCars(),

                                        // Parking sign
                                        Positioned(
                                          top: 100,
                                          right: 50,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..setEntry(3, 2, 0.001)
                                              ..rotateX(0.1)
                                              ..rotateY(0.2),
                                            child: SizedBox(
                                              width: 30,
                                              height: 40,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'P',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 2,
                                                    height: 20,
                                                    color: Colors.grey[300],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Location pin
                                        Positioned(
                                          top: 80,
                                          left: 80,
                                          child: Transform.scale(
                                            scale: 1.5,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom section with subtitle
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtitle
                    AnimatedBuilder(
                      animation: _subtitleController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _subtitleOpacity,
                            child: const Text(
                              'Smart Parking Solutions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildAnimatedCars() {
    return AnimatedBuilder(
      animation: _carsController,
      builder: (context, child) {
        return Stack(
          children: [
            // Green car (sliding from left)
            Positioned(
              top: 200,
              left: 30 + (40 * _carsAnimation.value),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.1)
                  ..rotateY(0.1),
                child: _buildCar(Colors.green, 60, 30),
              ),
            ),

            // Yellow car (sliding from right)
            Positioned(
              top: 160,
              right: 40 + (30 * _carsAnimation.value),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.1)
                  ..rotateY(-0.1),
                child: _buildCar(Colors.orange, 55, 28),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCar(Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Car windows
          Positioned(
            top: 4,
            left: 8,
            right: 8,
            child: Container(
              height: height * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Car wheels
          Positioned(
            bottom: -2,
            left: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParkingLotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw parking spaces
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        final rect = Rect.fromLTWH(
          20 + (i * (size.width - 40) / 4),
          50 + (j * 100),
          (size.width - 40) / 4 - 10,
          80,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
