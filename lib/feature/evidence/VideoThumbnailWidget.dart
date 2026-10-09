import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final XFile file;

  const VideoThumbnailWidget({super.key, required this.file});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _videoController;

  @override
  Widget build(BuildContext context) {
    if (_videoController?.value.isInitialized == true) {
      final size = _videoController!.value.size;
      return FittedBox(
        fit: BoxFit.fitWidth,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      return Center(child: CircularProgressIndicator(color: Colors.grey[900]));
    }
  }

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.file.path));
    _videoController
        ?.initialize()
        .then((_) {
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((e) {
          debugPrint("Erro ao inicializar thumbnail do vídeo: $e");
        });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
