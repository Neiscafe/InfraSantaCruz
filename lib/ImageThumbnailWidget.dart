import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImageThumbnailWidget extends StatelessWidget {
  const ImageThumbnailWidget({
    super.key,
    required this.onTap,
    required this.file,
    double? borderRadius,
  }) : borderRadius = borderRadius ?? 0;
  final double borderRadius;
  final void Function(XFile file) onTap;
  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) {
          return CircularProgressIndicator();
        }
        return InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTapUp: (_) => onTap(file),
          child: Image.memory(asyncSnapshot.requireData),
        );
      },
    );
  }
}
