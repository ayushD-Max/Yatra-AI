import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CustomMarkerHelper {
  static Future<BitmapDescriptor> createCustomMarker({
    required String imageUrl,
    required int index,
    required String title,
  }) async {
    final int size = 75; // Marker size
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw card background
    final Paint cardPaint = Paint()..color = Colors.white;
    final RRect cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      const Radius.circular(15),
    );

    // Draw shadow
    canvas.drawShadow(
      Path()..addRRect(cardRect),
      Colors.black.withValues(alpha: 0.5),
      10,
      false,
    );
    canvas.drawRRect(cardRect, cardPaint);

    // Load Image
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: size,
          targetHeight: size,
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image image = frameInfo.image;

        // Clip image
        canvas.save();
        canvas.clipRRect(cardRect);
        canvas.drawImage(image, Offset.zero, Paint());
        canvas.restore();
      }
    } catch (e) {
      // Fallback if image fails
    }

    // Draw dark gradient at bottom for text readability
    final Rect gradientRect = Rect.fromLTWH(
      0,
      size * 0.5,
      size.toDouble(),
      size * 0.4,
    );
    final Paint gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, gradientRect.top),
        Offset(0, gradientRect.bottom),
        [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
      );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        gradientRect,
        bottomLeft: const Radius.circular(15),
        bottomRight: const Radius.circular(15),
      ),
      gradientPaint,
    );

    // Draw Title
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: title,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: size - 12.toDouble());
    textPainter.paint(canvas, Offset(6, size - textPainter.height - 6));

    // Draw Badge (Top right)
    final Paint badgePaint = Paint()..color = const Color(0xFF007AFF);
    final double badgeRadius = 10;
    final Offset badgeCenter = Offset(size - badgeRadius - 4, badgeRadius + 4);

    // White border for badge
    canvas.drawCircle(
      badgeCenter,
      badgeRadius + 1.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    // Badge Text
    final TextPainter badgeTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    badgeTextPainter.text = TextSpan(
      text: '$index',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    badgeTextPainter.layout();
    badgeTextPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - badgeTextPainter.width / 2,
        badgeCenter.dy - badgeTextPainter.height / 2,
      ),
    );

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }
}
