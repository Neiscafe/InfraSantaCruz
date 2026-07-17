import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImageThumbnailWidget extends StatelessWidget {
  const ImageThumbnailWidget({
    super.key,
    required this.onTap,
    required this.file,
  });

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
        return GestureDetector(
          child: Image.memory(asyncSnapshot.requireData, fit: BoxFit.fill),
          onTap: () => onTap(file),
        );
      },
    );
  }
}
