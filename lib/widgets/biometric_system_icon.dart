import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget hiển thị biểu tượng sinh trắc học chuẩn hệ thống:
/// - iOS / macOS (Face ID): Biểu tượng khung quét Apple [CupertinoIcons.viewfinder]
///   lồng icon mặt nhận diện [Icons.face_unlock_rounded] ở tâm.
/// - Android / Khác (Vân tay): Biểu tượng [Icons.fingerprint_rounded].
class BiometricSystemIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool? isFaceId;

  const BiometricSystemIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.isFaceId,
  });

  bool _useFaceId(BuildContext context) {
    if (isFaceId != null) return isFaceId!;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryBlue;

    if (_useFaceId(context)) {
      // Biểu tượng Face ID chuẩn Apple: Khung quét viewfinder lồng icon mặt ở tâm
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              CupertinoIcons.viewfinder,
              size: size,
              color: effectiveColor,
            ),
            Icon(
              Icons.face_unlock_rounded,
              size: size * 0.52,
              color: effectiveColor,
            ),
          ],
        ),
      );
    }

    // Biểu tượng Vân tay chuẩn cho Android / Samsung
    return Icon(
      Icons.fingerprint_rounded,
      size: size,
      color: effectiveColor,
    );
  }
}
