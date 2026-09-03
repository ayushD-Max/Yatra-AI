import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/glass_container.dart';

class PlaceOverviewScreen extends StatefulWidget {
  final Place place;

  const PlaceOverviewScreen({super.key, required this.place});

  @override
  State<PlaceOverviewScreen> createState() => _PlaceOverviewScreenState();
}

class _PlaceOverviewScreenState extends State<PlaceOverviewScreen> {
  bool _isLoadingAi = false;
  String? _aiResponse;

  Future<void> _askYatraAi() async {
    setState(() {
      _isLoadingAi = true;
      _aiResponse = null;
    });

    // Bottom sheet loading UI
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      //const Text('', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        'Yatra AI Insights',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoadingAi)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    )
                  else if (_aiResponse != null)
                    Text(
                      _aiResponse!,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                    )
                  else
                    const Text('Failed to get insights.'),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://yatra.ai',
          'X-Title': 'Yatra AI',
        },
        body: jsonEncode({
          'model': 'minimax/minimax-m3:free',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are Yatra AI, an expert travel guide. Provide a fascinating 2-paragraph description of the given place. Include historical facts and what makes it special.',
            },
            {
              'role': 'user',
              'content': 'Tell me about ${widget.place.name} in Pune, India.',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        setState(() {
          _isLoadingAi = false;
          _aiResponse = text;
        });
        Navigator.pop(context);
        _showAiResultSheet(text);
      } else {
        Navigator.pop(context);
        _showAiResultSheet(
          'Could not fetch insights right now. Please try again.',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showAiResultSheet('An error occurred. Please try again.');
    }
  }

  void _showAiResultSheet(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        'Yatra AI Insights',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text,
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDirections() async {
    final encodedName = Uri.encodeComponent(widget.place.name);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedName',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Image with Curved Bottom
                ClipPath(
                  clipper: BottomCurveClipper(),
                  child: SizedBox(
                    height: screenHeight * 0.45,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        AppNetworkImage(
                          imageUrl: widget.place.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        ),
                        // Dark gradient for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Title overlaid on image
                        Positioned(
                          bottom: 50,
                          left: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.place.name,
                                style: AppTextStyles.h1.copyWith(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'India',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
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
                ),

                // Content Below Image
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EFFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🎭',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.place.category,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF6B4BA3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFB800),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.3',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF996B00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // About Section
                      Text(
                        'About',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.place.description.isNotEmpty
                            ? widget.place.description
                            : 'Explore the majestic ruins of this 18th-century Peshwa palace, a significant landmark in Pune\'s history.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),

                      // Removed Read more
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.withOpacity(0.2)),
                      const SizedBox(height: 16),

                      // Ask Yatra AI
                      InkWell(
                        onTap: _askYatraAi,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF007AFF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Ask Yatra AI about this spot',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: const Color(0xFF007AFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF007AFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Padding for bottom button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 30,
                  color: Colors.white.withValues(alpha: 0.2),
                  blur: 15,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          // Directions Sticky Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.white, Colors.white.withOpacity(0.0)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _openDirections,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Directions',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 50,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
