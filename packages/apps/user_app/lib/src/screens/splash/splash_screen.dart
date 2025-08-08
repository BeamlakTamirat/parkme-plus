import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _buttonController;
  late AnimationController _phoneController;
  late AnimationController _carsController;

  late Animation<double> _phoneAnimation;
  late Animation<double> _carsAnimation;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _buttonScale;

  bool _isFirstTime = true; // Check if it's first time opening the app

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _checkFirstTime() {
    // TODO: Check SharedPreferences for first time flag
    // For now, we'll assume it's first time to show onboarding
    _isFirstTime = true;
  }

  void _initializeAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Phone appearance animation
    _phoneController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Cars sliding in animation
    _carsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Title text animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Subtitle text animation
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    // Button animations
    _buttonOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    ));

    _buttonScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimationSequence() async {
    // Initialize backend
    await BackendService.instance.initialize();

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

    // If first time, show button to go to onboarding
    if (_isFirstTime) {
      await Future.delayed(const Duration(milliseconds: 400));
      _buttonController.forward();
    } else {
      // If not first time, wait and navigate directly to sign-in
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToSignIn();
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

  void _onGetStarted() {
    // Mark as not first time
    // TODO: Save to SharedPreferences
    _navigateToOnboarding();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _phoneController.dispose();
    _carsController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonController.dispose();
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
                                            child: Container(
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

              // Bottom section with subtitle and button
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

                    const SizedBox(height: 40),

                    // Get Started button (only for first time)
                    if (_isFirstTime)
                      AnimatedBuilder(
                        animation: _buttonController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _buttonOpacity,
                            child: ScaleTransition(
                              scale: _buttonScale,
                              child: ElevatedButton(
                                onPressed: _onGetStarted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFF5A623),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
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
