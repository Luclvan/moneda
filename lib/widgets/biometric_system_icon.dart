import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BiometricSystemIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool? forceFaceId;

  const BiometricSystemIcon({
    super.key,
    this.size = 26.0,
    this.color = const Color(0xFF1E40AF),
    this.forceFaceId,
  });

  bool get _useFaceId {
    if (forceFaceId != null) return forceFaceId!;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _useFaceId
            ? AppleFaceIdPainter(color: color)
            : SamsungFingerprintPainter(color: color),
      ),
    );
  }
}

class AppleFaceIdPainter extends CustomPainter {
  final Color color;
  AppleFaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.082
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = w * 0.13; // Bán kính bo góc khung
    final len = w * 0.27; // Độ dài cạnh góc
    final pad = w * 0.06;

    // 1. Vẽ 4 góc khung vuông bo tròn chuẩn Apple Face ID
    final corners = Path()
      // Góc trên - trái
      ..moveTo(pad, pad + len)
      ..lineTo(pad, pad + r)
      ..quadraticBezierTo(pad, pad, pad + r, pad)
      ..lineTo(pad + len, pad)
      // Góc trên - phải
      ..moveTo(w - pad - len, pad)
      ..lineTo(w - pad - r, pad)
      ..quadraticBezierTo(w - pad, pad, w - pad, pad + r)
      ..lineTo(w - pad, pad + len)
      // Góc dưới - trái
      ..moveTo(pad, h - pad - len)
      ..lineTo(pad, h - pad - r)
      ..quadraticBezierTo(pad, h - pad, pad + r, h - pad)
      ..lineTo(pad + len, h - pad)
      // Góc dưới - phải
      ..moveTo(w - pad - len, h - pad)
      ..lineTo(w - pad - r, h - pad)
      ..quadraticBezierTo(w - pad, h - pad, w - pad, h - pad - r)
      ..lineTo(w - pad, h - pad - len);
    canvas.drawPath(corners, cornersPaint(paint));

    // 2. Vẽ 2 mắt thẳng đứng
    canvas.drawLine(Offset(w * 0.34, h * 0.33), Offset(w * 0.34, h * 0.43), paint);
    canvas.drawLine(Offset(w * 0.66, h * 0.33), Offset(w * 0.66, h * 0.43), paint);

    // 3. Vẽ sống mũi chữ J / L ngược ở chính giữa
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.53)
      ..quadraticBezierTo(w * 0.50, h * 0.57, w * 0.45, h * 0.57)
      ..lineTo(w * 0.43, h * 0.57);
    canvas.drawPath(nose, paint);

    // 4. Vẽ miệng cười cong nhẹ bên dưới
    final mouth = Path()
      ..moveTo(w * 0.35, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.79, w * 0.65, h * 0.68);
    canvas.drawPath(mouth, paint);
  }

  Paint cornersPaint(Paint base) => base;

  @override
  bool shouldRepaint(covariant AppleFaceIdPainter oldDelegate) =>
      oldDelegate.color != color;
}

class SamsungFingerprintPainter extends CustomPainter {
  final Color color;
  SamsungFingerprintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 0.5, h * 0.54);
    // Các vòng vân tay đồng tâm chuẩn Samsung
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.42),
      3.5,
      2.4,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.31),
      3.0,
      3.4,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.20),
      2.6,
      4.2,
      false,
      paint,
    );
    final core = Path()
      ..moveTo(w * 0.42, h * 0.78)
      ..quadraticBezierTo(w * 0.50, h * 0.52, w * 0.50, h * 0.44)
      ..quadraticBezierTo(w * 0.50, h * 0.65, w * 0.58, h * 0.80);
    canvas.drawPath(core, paint);
  }

  @override
  bool shouldRepaint(covariant SamsungFingerprintPainter oldDelegate) =>
      oldDelegate.color != color;
}
