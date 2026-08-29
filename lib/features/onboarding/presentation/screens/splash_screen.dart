import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../home/presentation/cubit/home_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Preload home data so there's no loading spinner when transitioning
    context.read<HomeCubit>().loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Prevent accidental swipes revealing black background
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              // Page 1
              _buildImagePage(
                'assets/Splash_screen_img/1.png',
                Alignment.center,
              ),
              // Page 2 - Using topCenter so the bottom text doesn't get pushed too far down
              _buildImagePage(
                'assets/Splash_screen_img/2.png',
                Alignment.topCenter,
              ),
            ],
          ),

          // Overlays
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 8),
                    _buildDot(1),
                  ],
                ),
                const SizedBox(height: 32),

                // Controls
                if (_currentPage == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          borderRadius: 30,
                          color: const Color.fromARGB(146, 166, 161, 161),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                          blur: 15,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color.fromARGB(179, 255, 255, 255),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          borderRadius: 30,
                          color: const Color.fromRGBO(
                            255,
                            255,
                            255,
                            1,
                          ).withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          blur: 20,
                          child: Row(
                            children: [
                              Text(
                                'Next',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SlideActionButton(
                    text: 'Get Started',
                    onSlideComplete: () {
                      context.go('/home');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePage(String imagePath, Alignment alignment) {
    return SizedBox.expand(
      child: Image.asset(imagePath, fit: BoxFit.cover, alignment: alignment),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SlideActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onSlideComplete;

  const SlideActionButton({
    super.key,
    required this.text,
    required this.onSlideComplete,
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton> {
  double _dragPosition = 0;
  bool _isFinished = false;
  final double _buttonSize = 48.0; // Reduced from 56.0
  final double _padding = 6.0; // Reduced from 8.0

  void _reset() {
    if (mounted) {
      setState(() {
        _isFinished = false;
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _buttonSize - (_padding * 2);

        return GlassContainer(
          padding: EdgeInsets.all(_padding),
          borderRadius: 40,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          blur: 20,
          child: SizedBox(
            height: _buttonSize,
            child: Stack(
              children: [
                // Text and Chevrons
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        widget.text,
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                // Draggable Button
                AnimatedPositioned(
                  duration: _dragPosition == 0
                      ? const Duration(milliseconds: 300)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  left: _dragPosition,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (_isFinished) return;
                      setState(() {
                        _dragPosition += details.delta.dx;
                        if (_dragPosition < 0) _dragPosition = 0;
                        if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_isFinished) return;
                      if (_dragPosition > maxDrag * 0.75) {
                        setState(() {
                          _dragPosition = maxDrag;
                          _isFinished = true;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onSlideComplete();
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            _reset,
                          );
                        });
                      } else {
                        setState(() {
                          _dragPosition = 0;
                        });
                      }
                    },
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black87,
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
